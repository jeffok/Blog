#!/bin/bash

echo "=========================================="
echo "Jekyll Blog 本地测试脚本"
echo "=========================================="
echo ""

# 检查 Docker 是否运行
echo "1. 检查 Docker 状态..."
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi
echo "✅ Docker 正在运行"
echo ""

# 检查平台
echo "2. 检查系统平台..."
ARCH=$(uname -m)
echo "   系统架构: $ARCH"
if [ "$ARCH" = "arm64" ]; then
    echo "✅ 检测到 Apple Silicon (ARM64)，已配置平台支持"
else
    echo "ℹ️  检测到 x86_64 架构"
fi
echo ""

# 停止旧容器
echo "3. 清理旧容器..."
docker-compose down 2>/dev/null
echo "✅ 清理完成"
echo ""

# 构建并启动
echo "4. 构建并启动 Jekyll 服务..."
echo "   这可能需要几分钟时间（首次构建需要下载镜像）..."
docker-compose up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 服务启动成功！"
    echo "=========================================="
    echo ""
    echo "访问地址: http://localhost:4000"
    echo ""
    echo "查看日志: docker-compose logs -f"
    echo "停止服务: docker-compose down"
    echo ""
    echo "等待 10 秒后检查服务状态..."
    sleep 10
    docker-compose ps
else
    echo ""
    echo "❌ 启动失败，请检查错误信息"
    echo "查看日志: docker-compose logs"
    exit 1
fi
