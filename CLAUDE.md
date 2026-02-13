# CLAUDE.md

Guide for AI assistants working with this repository.

## Project Overview

Docker orchestration configuration for full-stack Node.js applications with:
- **Backend**: Express.js (port 3001)
- **Frontend**: Next.js (port 3000)
- **Database**: Microsoft SQL Server 2022 (port 1433)
- **Cache**: Redis 7 (port 6379)

Architecture:
```
Frontend (Next.js:3000) → Backend (Express:3001) → SQL Server (1433)
                                                  → Redis (6379)
```

This repository contains **only the Docker orchestration layer**. The actual backend and frontend source code live in separate directories referenced via `BACKEND_PATH` and `FRONTEND_PATH` in `.env`.

## Repository Structure

```
.
├── CLAUDE.md                       # This file
├── README.md                       # Project documentation (Traditional Chinese)
├── .env.example                    # Environment variable template
├── .gitignore                      # Git ignore rules
├── build.sh                        # Production image build script
├── docker-compose.yml              # Base service definitions
├── docker-compose.override.yml     # Development overrides (auto-loaded)
├── docker-compose.prod.yml         # Production overrides
└── sqlserver/
    └── .gitignore                  # Ignores sqlserver/backup/
```

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Base configuration: all 4 services, networks, volumes, healthchecks |
| `docker-compose.override.yml` | Dev environment: inline Dockerfiles, volume mounts for hot-reload, `npm run dev` |
| `docker-compose.prod.yml` | Prod environment: references pre-built `myapp-backend` / `myapp-frontend` images |
| `build.sh` | Builds production Docker images from external Dockerfiles |
| `.env.example` | Template for all required environment variables |

## Development Workflow

### Setup
1. Copy `.env.example` to `.env`
2. Set `BACKEND_PATH` and `FRONTEND_PATH` to point to the backend/frontend project directories
3. Set `SA_PASSWORD` meeting SQL Server complexity requirements (uppercase + lowercase + numbers + special chars, 8+ chars)
4. Run `docker compose up`

### Development mode
```bash
docker compose up
```
This automatically loads `docker-compose.override.yml`, which:
- Builds lightweight dev images inline (Node 20-alpine)
- Volume-mounts source code for hot-reload
- Excludes `node_modules` and `.next` from mounts (uses container versions)
- Runs `npm run dev` for both backend and frontend

### Production mode
```bash
./build.sh                # Build images (options: --backend, --frontend, --no-cache)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### build.sh options
- `--backend` — build only the backend image
- `--frontend` — build only the frontend image
- `--no-cache` — build without Docker cache
- No args — builds both images

## Environment Variables

Defined in `.env` (see `.env.example` for template):

| Variable | Description |
|----------|-------------|
| `NODE_ENV` | `development` or `production` |
| `BACKEND_PATH` / `FRONTEND_PATH` | Paths to source code directories |
| `FRONTEND_PORT` / `BACKEND_PORT` / `SQL_PORT` / `REDIS_PORT` | Service ports |
| `SA_PASSWORD` | SQL Server SA password (must meet complexity rules) |
| `MSSQL_PID` | SQL Server edition (`Developer`, `Express`, etc.) |
| `DB_NAME` / `DB_USER` | Database name and user |
| `REDIS_PASSWORD` | Optional Redis password |
| `JWT_SECRET` / `API_SECRET` | Application secrets |
| `NEXTAUTH_URL` / `NEXTAUTH_SECRET` | NextAuth.js configuration |
| `NEXT_PUBLIC_API_URL` | Public API URL for frontend |

## Docker Services

### Service dependency chain
```
sqlserver (healthcheck: sqlcmd SELECT 1)
redis     (healthcheck: redis-cli ping)
  └→ backend (healthcheck: wget /health) — depends on sqlserver + redis
       └→ frontend (healthcheck: wget /) — depends on backend
```

Services use `condition: service_healthy` so they wait for actual readiness, not just container start.

### Container names
- `sqlserver_db`
- `redis_cache`
- `express_backend`
- `nextjs_frontend`

### Network
All services share a single bridge network: `app-network`.

### Volumes
- `sqlserver_data` — persistent SQL Server data
- `redis_data` — persistent Redis data
- `./sqlserver/backup` — bind-mount for SQL Server backup files

## Conventions

### Naming
- Container names: `service_type` pattern (e.g., `sqlserver_db`, `express_backend`)
- Environment variables: `UPPERCASE_WITH_UNDERSCORES`
- Docker images: `myapp-service` pattern (e.g., `myapp-backend`)

### Commit messages
Follow the pattern: `type: description`
- `init:` — initial setup
- `mod:` — modifications/updates

### Security practices
- Non-root user execution in containers (uid 1001)
- Secrets via environment variables, never hardcoded
- SQL Server uses ODBC Driver 18 with TLS (`sqlcmd -C` flag)
- Strong password requirements enforced for SA_PASSWORD

### Docker Compose layering
- Base config in `docker-compose.yml` (always loaded)
- Dev overrides in `docker-compose.override.yml` (auto-loaded by `docker compose up`)
- Prod overrides in `docker-compose.prod.yml` (explicitly specified with `-f`)

## Important Notes

- **No CI/CD pipelines** exist in this repository. Deployment is manual via `build.sh` + docker compose.
- **No test suite** in this repo. Testing lives in the backend/frontend projects.
- **No database migration scripts** in this repo. Schema management is handled by the backend project.
- **Frontend uses `--legacy-peer-deps`** for npm install due to peer dependency conflicts.
- The SQL Server healthcheck uses `/opt/mssql-tools18/bin/sqlcmd` (ODBC Driver 18), not the older `/opt/mssql-tools/bin/sqlcmd`.
- Redis password is conditionally applied via shell command in the compose file.
