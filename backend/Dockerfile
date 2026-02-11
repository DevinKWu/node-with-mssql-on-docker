FROM node:20-alpine

# 建立非 root 使用者
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# 複製 package 檔案並安裝依賴
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --omit=dev

# 複製應用程式碼
COPY --chown=nodejs:nodejs . .

USER nodejs

ARG PORT=3001
EXPOSE ${PORT}

CMD ["npm", "start"]
