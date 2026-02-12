FROM jekyll/jekyll:latest

WORKDIR /srv/jekyll

# 复制依赖文件
COPY Gemfile Gemfile.lock* ./

# 安装依赖
RUN bundle install

# 复制所有文件
COPY . .

# 暴露端口
EXPOSE 4000

# 启动 Jekyll 服务器
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--force_polling"]
