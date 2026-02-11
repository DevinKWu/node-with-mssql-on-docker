FROM node:20-alpine AS base
WORKDIR /app

# 開發階段
FROM base AS dev
COPY package*.json ./
RUN npm ci
CMD ["npm", "run", "dev"]

# 建構階段
FROM base AS builder
COPY --from=src package*.json ./
RUN npm ci
COPY --from=src . .
RUN npm run build

# 生產階段 - 完整模式（不需要 standalone 設定）
FROM node:20-alpine AS runner-full
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app ./

USER nextjs

ARG PORT=3000
EXPOSE ${PORT}

CMD ["npm", "start"]

# 生產階段 - standalone 模式（需要 next.config.js 設定 output: 'standalone'）
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER nextjs

ARG PORT=3000
EXPOSE ${PORT}

CMD ["node", "server.js"]
