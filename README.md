# Node.js + MSSQL on Docker

## 專案結構

```
project-root/
├── docker-compose.yml            # 共用基礎設定（服務、網路、volumes）
├── docker-compose.override.yml   # 開發環境（自動載入）
├── docker-compose.prod.yml       # 生產環境
├── build.sh                      # 生產 image 建構腳本
├── nginx/
│   ├── default.conf              # Nginx 開發設定（HTTP）
│   └── default.prod.conf         # Nginx 生產設定（SSL）
├── sqlserver/
│   └── backup/                   # SQL Server 備份目錄
├── .env                          # 環境變數（不進版控）
├── .env.example                  # 環境變數範本
└── .gitignore
```

> 前後端 Dockerfile 各自存放在對應的專案目錄中（由 `BACKEND_PATH`、`FRONTEND_PATH` 指定）。

## 服務架構

| 服務 | Image | 用途 | Container 內部 Port |
|---|---|---|---|
| nginx | nginx:alpine | 反向代理 / SSL termination | 80 / 443 |
| frontend | Node.js 20 Alpine | Next.js 前端 | 3000 |
| backend | Node.js 20 Alpine | Express 後端 | 3001 |
| sqlserver | mssql/server:2022-latest | SQL Server 資料庫 | 1433 |
| redis | redis:7-alpine | Redis 快取 | 6379 |

### 依賴鏈

```
sqlserver (healthcheck: sqlcmd SELECT 1)
redis     (healthcheck: redis-cli ping)
  └→ backend (healthcheck: wget /health) — depends on sqlserver + redis
       └→ frontend (healthcheck: wget /) — depends on backend
            └→ nginx — depends on backend + frontend
```

### 網路拓撲

```
                           ┌→ frontend (:3000) ─┐
Client → Nginx (:80/443) ──┤                     ├→ sqlserver (:1433)
                           └→ backend  (:3001) ──┤
                                                 └→ redis (:6379)
```

Nginx 依 URL path 分流：`/api` → backend，`/` → frontend。

所有服務位於同一 bridge network (`app-network`)，僅 Nginx 對外開放 port。

## 快速開始

### 1. 設定環境變數

```bash
cp .env.example .env
```

編輯 `.env`，填入實際值（特別是 `SA_PASSWORD`、`BACKEND_PATH`、`FRONTEND_PATH`）。

### 2. 啟動開發環境

```bash
docker compose up
```

自動載入 `docker-compose.override.yml`，行為如下：

- 以 `dockerfile_inline` 建構輕量 dev image（Node 20 Alpine）
- Volume mount 前後端 source code，支援 hot-reload
- **所有服務開放 host port**，可直接存取：

| 服務 | URL |
|---|---|
| Frontend | `http://localhost:3000` |
| Backend | `http://localhost:3001` |
| Nginx（統一入口） | `http://localhost` |
| SQL Server | `localhost:1433`（SSMS / Azure Data Studio） |
| Redis | `localhost:6379`（RedisInsight 等工具） |

> Host port 可透過 `.env` 調整（`FRONTEND_PORT`、`BACKEND_PORT`、`SQL_PORT`、`REDIS_PORT`、`NGINX_PORT`），容器內部 port 固定不變。

### 3. 啟動生產環境

#### 3-1. 建構 image

```bash
./build.sh
```

可選參數：
- `--backend` — 只建構後端 image
- `--frontend` — 只建構前端 image
- `--no-cache` — 不使用 Docker cache

#### 3-2. 設定 SSL 憑證

在 `.env` 中設定憑證路徑：

```bash
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com
```

目錄內需包含：
- `fullchain.pem` — 完整憑證鏈
- `privkey.pem` — 私鑰

#### 3-3. 啟動服務

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

生產環境行為：
- **只有 Nginx 對外**開放 port 80 和 443
- HTTP 自動 301 redirect 到 HTTPS
- 啟用 HSTS header
- 前後端、資料庫、快取完全不對外暴露

### 4. 常用指令

```bash
# 查看日誌
docker compose logs -f

# 查看特定服務日誌
docker compose logs -f nginx backend

# 只啟動特定服務
docker compose up -d sqlserver redis

# 停止服務
docker compose down

# 重新建構開發 image
docker compose build --no-cache

# 重新建構生產 image 並啟動
./build.sh --no-cache && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Docker Compose 分層說明

| 檔案 | 載入方式 | 用途 |
|---|---|---|
| `docker-compose.yml` | 永遠載入 | 所有服務的基礎定義，無 port 對外暴露 |
| `docker-compose.override.yml` | `docker compose up` 自動載入 | 開發用：inline Dockerfile、volume mount、開放所有 port |
| `docker-compose.prod.yml` | 需明確指定 `-f` | 生產用：引用預建 image、Nginx SSL 掛載 |

## 環境變數

參考 `.env.example`，主要設定項：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `BACKEND_PATH` | 後端專案路徑（需含 Dockerfile） | - |
| `FRONTEND_PATH` | 前端專案路徑（需含 Dockerfile） | - |
| `SA_PASSWORD` | SQL Server SA 密碼 | - |
| `DB_NAME` | 資料庫名稱 | - |
| `BACKEND_PORT` | 後端 host port（容器內部固定 3001） | 3001 |
| `FRONTEND_PORT` | 前端 host port（容器內部固定 3000） | 3000 |
| `SQL_PORT` | SQL Server host port（容器內部固定 1433） | 1433 |
| `REDIS_PORT` | Redis host port（容器內部固定 6379） | 6379 |
| `NGINX_PORT` | Nginx host port（開發環境） | 80 |
| `SSL_CERT_PATH` | SSL 憑證目錄（生產環境） | - |
| `REDIS_PASSWORD` | Redis 密碼（選填） | - |
| `JWT_SECRET` | JWT 密鑰 | - |

> **Port 設計原則**：`.env` 中的 port 變數只控制 host 對外映射，容器內部 port 固定。非 Docker 開發者可在前後端專案各自的 `.env` 中設定 `PORT`，兩邊互不影響。

## 注意事項

- `SA_PASSWORD` 須符合 SQL Server 密碼複雜度要求（大小寫 + 數字 + 特殊字元，至少 8 碼）
- 生產環境務必使用強密碼，不要使用 `.env.example` 中的範例值
- SSL 憑證建議使用 [Let's Encrypt](https://letsencrypt.org/) + certbot 自動申請與續期
- Nginx 反向代理已配置 WebSocket 支援（`Connection: upgrade`），Next.js HMR 可正常運作
- 前端使用 standalone 模式前，須在 `next.config` 加上 `output: 'standalone'`
