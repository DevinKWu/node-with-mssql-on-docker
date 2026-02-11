# Node.js + MSSQL on Docker

## 專案結構

```
project-root/
├── docker-compose.yml            # 共用基礎設定
├── docker-compose.override.yml   # 開發環境（自動載入）
├── docker-compose.prod.yml       # 生產環境 - standalone
├── docker-compose.prod-full.yml  # 生產環境 - 完整模式
├── .env                          # 環境變數（不進版控）
├── .env.example                  # 環境變數範本
├── .gitignore
├── backend/
│   └── Dockerfile                # 後端 multi-stage（dev / production）
├── frontend/
│   └── Dockerfile                # 前端 multi-stage（dev / builder / runner-full / runner）
└── sqlserver/
    └── backup/                   # SQL Server 備份目錄
```

## 服務架構

| 服務 | Image | 用途 | 預設 Port |
|---|---|---|---|
| sqlserver | mssql/server:2022-latest | SQL Server 資料庫 | 1433 |
| redis | redis:7-alpine | Redis 快取 | 6379 |
| backend | Node.js 20 Alpine | Express 後端 | 3001 |
| frontend | Node.js 20 Alpine | Next.js 前端 | 3000 |

**依賴鏈**：frontend → backend → sqlserver + redis

## 快速開始

### 1. 設定環境變數

```bash
cp .env.example .env
```

編輯 `.env`，填入實際值（特別是 `SA_PASSWORD`、`BACKEND_PATH`、`FRONTEND_PATH`）。

### 2. 啟動服務

#### 開發環境

```bash
docker compose up
```

自動載入 `docker-compose.override.yml`，前後端使用 `npm run dev` + volume mount 支援 hot-reload。

#### 生產環境 - standalone（推薦）

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

前端需要在 `next.config.js` 設定 `output: 'standalone'`，image 體積最小。

#### 生產環境 - 完整模式

```bash
docker compose -f docker-compose.yml -f docker-compose.prod-full.yml up -d
```

不需要 standalone 設定，相容性較高，image 較大。

### 3. 常用指令

```bash
# 查看日誌
docker compose logs -f

# 只啟動特定服務
docker compose up -d sqlserver redis

# 停止服務
docker compose down

# 重新建構 image
docker compose build --no-cache
```

## Dockerfile multi-stage 說明

### 後端（backend/Dockerfile）

| Stage | Target | 用途 |
|---|---|---|
| base | - | 共用：建立使用者、設定 WORKDIR |
| dev | `dev` | 開發：`npm ci` → `npm run dev` |
| production | `production` | 生產：`npm ci --omit=dev` → `npm start` |

### 前端（frontend/Dockerfile）

| Stage | Target | 用途 |
|---|---|---|
| base | - | 共用：設定 WORKDIR |
| dev | `dev` | 開發：`npm ci` → `npm run dev` |
| builder | - | 建構：`npm ci` → `npm run build` |
| runner-full | `runner-full` | 生產（完整）：保留 node_modules → `npm start` |
| runner | `runner` | 生產（standalone）：僅 standalone output → `node server.js` |

## 環境變數

參考 `.env.example`，主要設定項：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `BACKEND_PATH` | 後端原始碼路徑 | - |
| `FRONTEND_PATH` | 前端原始碼路徑 | - |
| `SA_PASSWORD` | SQL Server SA 密碼 | - |
| `DB_NAME` | 資料庫名稱 | - |
| `BACKEND_PORT` | 後端 Port | 3001 |
| `FRONTEND_PORT` | 前端 Port | 3000 |
| `REDIS_PASSWORD` | Redis 密碼（選填） | - |
| `JWT_SECRET` | JWT 密鑰 | - |

## 注意事項

- `SA_PASSWORD` 須符合 SQL Server 密碼複雜度要求（大小寫 + 數字 + 特殊字元，至少 8 碼）
- 開發環境的 volume mount 會覆蓋 image 內的檔案，`./backend` 和 `./frontend` 目錄的 `package.json` 須與實際專案一致
- 前端使用 standalone 模式前，須在 `next.config.js` 加上 `output: 'standalone'`
- 生產環境務必使用強密碼，不要使用 `.env.example` 中的範例值
