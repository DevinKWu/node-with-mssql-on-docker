# 專案結構

```
project-root/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   │   ├── app.js
│   │   ├── routes/
│   │   ├── models/
│   │   └── middleware/
│   └── ...
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── next.config.js
│   ├── pages/ (或 app/ 如果使用 App Router)
│   ├── components/
│   └── ...
└── init-scripts/
    └── init.sql
```

## 使用方法

1. **建立專案目錄結構**
2. **設定環境變數**：複製 `.env.example` 到 `.env` 並填入實際值
3. **啟動服務**：
   ```bash
   docker-compose up -d
   ```
4. **查看日誌**：
   ```bash
   docker-compose logs -f
   ```
5. **停止服務**：
   ```bash
   docker-compose down
   ```

## 注意事項

- 確保 SA_PASSWORD 符合 SQL Server 密碼複雜度要求
- 在生產環境中使用強密碼和安全金鑰
- 定期備份資料庫資料
- 根據需求調整健康檢查設定
