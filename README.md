# Jeff 的技术博客

基于 [Jekyll Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 主题的技术博客，使用 GitHub Actions 自动构建并部署到 GitHub Pages。

## 本地开发

使用 Docker（ARM64 原生支持，Apple Silicon 友好）：

```bash
# 启动开发服务器
docker-compose up

# 后台运行
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f
```

访问 http://localhost:4000

**特性：** ARM64 原生支持 | Ruby 3.3 + Debian bookworm | Node.js/npm（支持 PageCrypt）| 自动热重载

## 部署

推送代码到 GitHub 后，GitHub Actions 会自动构建并部署到 GitHub Pages。

**配置步骤：**
1. 仓库 **Settings → Pages**
2. Build and deployment → Source：选择 **GitHub Actions**

## 配置

### 自定义域名
项目已包含 `CNAME`（jeffok.com），在仓库 Settings → Pages → Custom domain 中启用。

### 评论系统（giscus）
1. 访问 [giscus.app](https://giscus.app)
2. 选择仓库，启用 Discussions，创建 `General` 分类
3. 将 `repo_id` 和 `category_id` 填入 `_config.yml`

### 页面加密（PageCrypt）
1. 在 `_data/encrypted_pages.yml` 中列出需加密的页面路径
2. 在 GitHub Secrets 中创建 `PAGECRYPT_PASSWORD`
3. 构建后对应页面需要密码访问
