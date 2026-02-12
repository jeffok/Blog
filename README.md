# Jeff 的技术博客

基于 [Jekyll Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 主题的技术博客，使用 GitHub Actions 自动构建并部署到 GitHub Pages。

## 本地开发

### 使用 Docker（推荐，无需安装 Ruby）

```bash
# 方式一：使用 docker-compose（推荐）
docker-compose up

# 方式二：直接使用 Docker
docker build -t my-blog .
docker run -p 4000:4000 -v $(pwd):/srv/jekyll my-blog
```

访问 http://localhost:4000

### 使用本地 Ruby（需要 Ruby 3.1+）

```bash
bundle install
bundle exec jekyll serve
```

## 部署流程

1. 将本仓库推送到 GitHub（例如 `jeffok/Blog`）
2. 在仓库 **Settings → Pages** 中，将 Source 设为 **GitHub Actions**
3. 推送后会自动触发构建并发布

## 自定义域名

- 已在项目中包含 `CNAME`（jeffok.com）
- 在仓库 Settings → Pages → Custom domain 中填写 `jeffok.com` 并启用 HTTPS

## 评论系统（giscus）

1. 访问 [giscus.app](https://giscus.app)
2. 选择本仓库，启用 Discussions，创建 `General` 分类
3. 将生成的 `data-repo-id` 和 `data-category-id` 填入 `_config.yml` 的 `comments.giscus` 下

## 页面加密（PageCrypt）

需加密的少数页面：

1. 在 `_data/encrypted_pages.yml` 的 `pages` 下列出路径（如 `posts/private-post`）
2. 在 GitHub 仓库 **Settings → Secrets and variables → Actions** 中创建 `PAGECRYPT_PASSWORD`
3. 构建后对应页面将需要输入密码才能查看

## 附件

小附件直接放在 `assets/files/` 或 `images/`，在文章中用相对路径引用。大附件可后续迁移到 Releases。
