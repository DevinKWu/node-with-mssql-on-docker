FROM node:20-alpine AS base

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# 開發階段
FROM base AS dev
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci
USER nodejs
ARG PORT=3001
EXPOSE ${PORT}
CMD ["npm", "run", "dev"]

# 生產階段
FROM base AS production
COPY --from=src --chown=nodejs:nodejs package*.json ./
RUN npm ci --omit=dev
COPY --from=src --chown=nodejs:nodejs . .
USER nodejs
ARG PORT=3001
EXPOSE ${PORT}
CMD ["npm", "start"]
