FROM ruby:3.3-bookworm

# 基础工具 + 编译依赖（避免 native gem 编译失败）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates build-essential pkg-config \
    libxml2-dev libxslt1-dev zlib1g-dev \
    nodejs npm \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/jekyll

# Bundler 更稳定：把 gems 装到容器缓存目录
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

EXPOSE 4000 35729
