#!/bin/sh
set -e

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --backend       只建構 backend"
  echo "  --frontend      只建構 frontend"
  echo "  --no-cache      不使用快取重新建構"
  echo "  -h, --help      顯示說明"
  echo ""
  echo "不帶參數時建構全部 image。"
}

# 載入 .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

BACKEND_PATH="${BACKEND_PATH:?BACKEND_PATH is not set in .env}"
FRONTEND_PATH="${FRONTEND_PATH:?FRONTEND_PATH is not set in .env}"

BUILD_BACKEND=false
BUILD_FRONTEND=false
NO_CACHE=""

# 解析參數
for arg in "$@"; do
  case "$arg" in
    --backend)   BUILD_BACKEND=true ;;
    --frontend)  BUILD_FRONTEND=true ;;
    --no-cache)  NO_CACHE="--no-cache" ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

# 不帶參數時建構全部
if [ "$BUILD_BACKEND" = false ] && [ "$BUILD_FRONTEND" = false ]; then
  BUILD_BACKEND=true
  BUILD_FRONTEND=true
fi

if [ "$BUILD_BACKEND" = true ]; then
  echo "Building backend image..."
  docker build $NO_CACHE -t myapp-backend "$BACKEND_PATH"
fi

if [ "$BUILD_FRONTEND" = true ]; then
  echo "Building frontend image..."
  docker build $NO_CACHE -t myapp-frontend "$FRONTEND_PATH"
fi

echo "Build complete."
