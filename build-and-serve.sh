#!/bin/bash

echo "=========================================="
echo "Jekyll Blog 构建和测试脚本"
echo "=========================================="
echo ""

# 检查 Docker 是否运行
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

echo "✅ Docker 正在运行"
echo ""

# 使用 GitHub Actions 的方式构建（在容器中构建，但使用官方镜像）
echo "1. 使用 Jekyll 官方镜像构建静态站点..."
docker run --rm \
  --platform linux/amd64 \
  -v "$PWD:/srv/jekyll" \
  -v "$PWD/vendor/bundle:/usr/local/bundle" \
  jekyll/jekyll:latest \
  jekyll build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "2. 启动 nginx 服务器..."
    docker-compose -f docker-compose.serve.yml up -d
    
    echo ""
    echo "=========================================="
    echo "✅ 服务启动成功！"
    echo "=========================================="
    echo ""
    echo "访问地址: http://localhost:4000"
    echo ""
    echo "停止服务: docker-compose -f docker-compose.serve.yml down"
else
    echo ""
    echo "❌ 构建失败"
    exit 1
fi
