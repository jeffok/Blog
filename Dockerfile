# 使用 linux/amd64 平台以避免 sass-embedded 在 ARM64 上的问题
# 在 Apple Silicon Mac 上通过 Rosetta 2 运行
FROM --platform=linux/amd64 jekyll/jekyll:latest

WORKDIR /srv/jekyll

# 设置环境变量
ENV JEKYLL_ENV=development

# 复制依赖文件
COPY Gemfile ./

# 安装依赖（不锁定版本，让 bundler 自动解决）
RUN bundle install --without test

# 复制所有文件
COPY . .

# 暴露端口
EXPOSE 4000

# 启动 Jekyll 服务器
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--force_polling"]
