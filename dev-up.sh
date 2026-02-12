#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${IMAGE:-blog-chirpy:latest}"

echo "[dev-up] 使用镜像: ${IMAGE}"

if docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "[dev-up] 本地已有镜像，跳过构建"
else
  echo "[dev-up] 本地没有镜像，开始构建（仅第一次需要）"
  docker build -t "${IMAGE}" -f "${ROOT_DIR}/Dockerfile" "${ROOT_DIR}"
fi

echo "[dev-up] 启动/更新容器（代码通过 volume 挂载，不会触发编译镜像）"
docker-compose -f "${ROOT_DIR}/docker-compose.yml" up -d

echo "[dev-up] 容器状态："
docker-compose -f "${ROOT_DIR}/docker-compose.yml" ps

echo "[dev-up] 站点地址: http://localhost:4000"

