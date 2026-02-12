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

# 清理旧的构建
echo "1. 清理旧的构建文件..."
rm -rf _site vendor/bundle

# 使用 GitHub Actions 相同的方式构建（使用 Ruby setup）
echo ""
echo "2. 使用 Ruby 3.3 官方镜像构建静态站点..."
echo "   这可能需要几分钟时间（首次构建需要下载镜像和依赖）..."

# 使用 Ruby 官方镜像，完全模拟 GitHub Actions 环境
# 使用 host 网络模式以确保网络连接正常
docker run --rm \
  --platform linux/amd64 \
  --network host \
  -v "$PWD:/srv/jekyll" \
  -v "$PWD/vendor/bundle:/usr/local/bundle" \
  -w /srv/jekyll \
  -e JEKYLL_ENV=production \
  ruby:3.3-slim \
  bash -c "
    set -e
    apt-get update -qq
    apt-get install -y -qq build-essential git curl
    gem install bundler --no-document
    bundle config set --local path '/usr/local/bundle'
    bundle install --jobs 4 --retry 3
    bundle exec jekyll build -d _site
  "

BUILD_STATUS=$?
if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    
    # 检查 _site 目录是否存在
    if [ ! -d "_site" ] || [ -z "$(ls -A _site)" ]; then
        echo "❌ 错误：_site 目录为空或不存在"
        exit 1
    fi
    
    echo ""
    echo "3. 停止旧容器（如果有）..."
    docker-compose -f docker-compose.serve.yml down 2>/dev/null
    
    echo ""
    echo "4. 启动 nginx 服务器..."
    docker-compose -f docker-compose.serve.yml up -d --build
    
    # 等待服务启动
    sleep 3
    
    # 测试服务是否正常
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000 2>/dev/null || echo "000")
    
    echo ""
    echo "=========================================="
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ 服务启动成功！"
        echo "=========================================="
        echo ""
        echo "✅ HTTP 状态码: $HTTP_CODE"
        echo "✅ 访问地址: http://localhost:4000"
        echo ""
        echo "查看日志: docker-compose -f docker-compose.serve.yml logs -f"
        echo "停止服务: docker-compose -f docker-compose.serve.yml down"
    else
        echo "⚠️  服务已启动，但 HTTP 状态码: $HTTP_CODE"
        echo "=========================================="
        echo ""
        echo "访问地址: http://localhost:4000"
        echo "查看日志: docker-compose -f docker-compose.serve.yml logs"
    fi
else
    echo ""
    echo "❌ 构建失败"
    exit 1
fi
