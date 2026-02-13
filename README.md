# Node.js + MSSQL on Docker

## 專案結構

```
project-root/
├── docker-compose.yml            # 共用基礎設定（服務、網路、volumes）
├── docker-compose.override.yml   # 開發環境（自動載入）
├── docker-compose.prod.yml       # 生產環境
├── build.sh                      # 生產 image 建構腳本
├── .env                          # 環境變數（不進版控）
├── .env.example                  # 環境變數範本
├── .gitignore
└── sqlserver/
    └── backup/                   # SQL Server 備份目錄
```

> 前後端 Dockerfile 各自存放在對應的專案目錄中（由 `BACKEND_PATH`、`FRONTEND_PATH` 指定）。

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

自動載入 `docker-compose.override.yml`，以 `dockerfile_inline` 建構輕量 dev image，並透過 volume mount 支援 hot-reload。

#### 生產環境

```bash
./build.sh && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

`build.sh` 會讀取 `.env` 中的路徑，使用各專案目錄內的 Dockerfile 建構 image。前端 Dockerfile 會自動偵測 standalone 模式（若 `next.config` 有設定 `output: 'standalone'` 則以 `node server.js` 啟動，否則走傳統模式）。

### 3. 常用指令

```bash
# 查看日誌
docker compose logs -f

# 只啟動特定服務
docker compose up -d sqlserver redis

# 停止服務
docker compose down

# 重新建構開發 image
docker compose build --no-cache
```

## 環境變數

參考 `.env.example`，主要設定項：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `BACKEND_PATH` | 後端專案路徑（需含 Dockerfile） | - |
| `FRONTEND_PATH` | 前端專案路徑（需含 Dockerfile） | - |
| `SA_PASSWORD` | SQL Server SA 密碼 | - |
| `DB_NAME` | 資料庫名稱 | - |
| `BACKEND_PORT` | 後端 Port | 3001 |
| `FRONTEND_PORT` | 前端 Port | 3000 |
| `REDIS_PASSWORD` | Redis 密碼（選填） | - |
| `JWT_SECRET` | JWT 密鑰 | - |

## 注意事項

- `SA_PASSWORD` 須符合 SQL Server 密碼複雜度要求（大小寫 + 數字 + 特殊字元，至少 8 碼）
- 前端使用 standalone 模式前，須在 `next.config` 加上 `output: 'standalone'`
- 生產環境務必使用強密碼，不要使用 `.env.example` 中的範例值
