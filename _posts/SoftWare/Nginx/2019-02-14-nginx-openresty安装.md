---
title: nginx-openresty安装
date: 2019-02-14 16:44:00
tags: ["Nginx", "版本控制", "Git", "Web服务器"]
categories: ["SoftWare", "Nginx"]
render_with_liquid: false
permalink: /posts/2019-02-14-nginx-openresty安装/
---

本文档介绍 nginx-openresty安装 的相关内容。

## 编译安装openresty

```bash
# 创建目录

mkdir /tools
cd /tools

# 安装依赖软件包

yum install pcre-devel openssl-devel readline-devel gcc git gcc -y

# 创建nginx用户

useradd nginx -s /sbin/nologin -M

# nginx软件下载

wget https://openresty.org/download/openresty-1.2.3.4.tar.gz

# 解压

tar xf openresty-1.2.3.4.tar.gz
cd openresty-1.2.3.4

# 下载目录页面美化软件（可选,进入目录后下载）

git clone https://github.com/aperezdc/ngx-fancyindex.git ngx-fancyindex

# 编译

./configure --prefix=/usr/local/nginx \

-user=nginx --group=nginx --with-http_ssl_module \
-with-http_realip_module --with-http_stub_status_module \
-with-http_flv_module --with-http_gzip_static_module \
-with-pcre --http-proxy-temp-path=/usr/local/nginx/proxy/ \
-http-fastcgi-temp-path=/usr/local/nginx/fcgi/ \
-add-module=ngx-fancyindex -j8

# 如果支持多核加上-j4进行安装

make -j4 && make install

```

## Yum安装

```sql
# 你可以在你的 CentOS 系统中添加 openresty 仓库，这样就可以便于未来安装或更新我们的软件包（通过 yum update 命令）。运行下面的命令就可以添加我们的仓库：

yum install yum-utils
yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

# 然后就可以像下面这样安装软件包，比如 openresty：

yum install openresty

# 如果你想安装命令行工具 resty，那么可以像下面这样安装 openresty-resty 包：

yum install openresty-resty

# 命令行工具 opm 在 openresty-opm 包里，而 restydoc 工具在 openresty-doc 包里头。

# 列出所有 openresty 仓库里头的软件包：

yum --disablerepo="*" --enablerepo="openresty" list available

```

## 优化内核参数

```bash
# vim /etc/sysctl.conf

fs.file-max = 2000000
fs.nr_open = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 204800
net.ipv4.tcp_max_tw_buckets = 204800
net.ipv4.tcp_max_orphans = 204800
net.core.netdev_max_backlog =204800
net.core.somaxconn = 65000
vm.swappiness = 0

# vim /etc/security/limits.conf

# End of file

  *              soft    nofile          102400
  *              hard    nofile          102400

```
