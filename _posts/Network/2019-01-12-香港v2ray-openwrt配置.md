---
title: 香港v2ray-openwrt配置
date: 2019-01-12 13:41:00
tags: ["V2Ray", "容器", "网络", "代理", "Docker"]
categories: ['Network']
render_with_liquid: false
permalink: /posts/2019-01-12-香港v2ray-openwrt配置/
---

本文档介绍 香港v2ray-openwrt配置 的相关内容。

### 香港服务器配置

##### 安装docker、docker-compose

```bash
yum install -y docker-ce
pip install docker-compose

```

##### 安装配置v2ray

1. docker-compose.yml

```bash
    # docker-compose.yml （网络预先创建）
    version: "3.7"

    networks:
      app-network:
        external: true

    services:
      v2ray:
        image: v2ray/official:latest
        container_name: v2ray
        restart: always
        networks:

app-network
        ports:

10.100.11.254:7000:9000
        volumes:

./v2ray:/etc/v2ray

    # docker-compose.yml （网络自动创建）
    version: "3.7"

    networks:
      app-network:

    services:
      v2ray:
        image: v2ray/official:latest
        container_name: v2ray
        restart: always
        networks:

app-network
        ports:

127.0.0.1:7000:9000
        volumes:

./v2ray:/etc/v2ray

```

2. v2ray 配置文件

```bash
    # config.json
    {
      "inbounds": [
        {
          "port": 9000,
          "protocol": "vmess",
          "settings": {
            "clients": [
              {
                "id": "e14ffabf-fc20-45e4-a7ee-0c51d7df77c2",
                "level": 0,
                "alterId": 100
              }
            ]
          },
          "streamSettings": {
            "network": "ws",
            "security": "auto",
            "wsSettings": {
              "connectionReuse": true,
              "path": "/youku.com"
            }
          }
        }
      ],
      "outbounds": [
        {
          "protocol": "freedom",
          "settings": {}
        }
      ]
    }

    # port: docker 容器绑定的端口
    # protocol: 协议类型
    # id: 服务端与客户端的ID需要一致
    # level: 用户权限
    # alterId: 值越在超不容易被封，但消耗越大，默认64
    # network: 网络类型：ws、tcp、h2、kcp、domainsocket、quic     建议使用ws和h2,其它容易被封
    security: 加密类型 auto、aes-128-cfb....建议选择自动
    connectionReuse: 是否允许不验证域名证书
    path: 域名访问路径，用于配置nginx或其它转发工具

```

3. 配置完成后启动容器

```yaml
    docker-compose up -d

```

4. 配置nginx前端代理

```nginx
# 需要准备一个域名，且域名需要有一个证书，需要使用一个站点来提供web前端访问

upstream v2ray {
    server  10.100.11.254:7000 max_fails=3 fail_timeout=10s;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name  mirrors.jeffok.com;
    # include return.conf;
    if ($scheme = http ) {
        return 301 https://$host$request_uri;
    }

    if ($host != ${server_name}) {
        return 444;
    }

    ssl_certificate      ssl/mirrors.jeffok.com.pem;
    ssl_certificate_key  ssl/mirrors.jeffok.com.key;
    # include http_ssl.conf;
    ssl_protocols SSLv2 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:STATJGWW:64m;
    ssl_session_timeout 30m;

    charset utf-8;
    access_log      logs/mirrors_jeffok_com_access.log main;
    access_log      logs/mirrors_jeffok_com_access_json.log log_json;
    error_log       logs/mirrors_jeffok_com_error.log;

    location / {
        root /data/repo;
        autoindex on;
        autoindex_exact_size on;
        autoindex_localtime on;
        # include proxy_set_header.conf;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    }

    location /youku.com {
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 300s;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://v2ray;
    }
}

```

### openwrt 配置

> newifi3 固件地址：./File_Software目录中

<img src=http://note.youdao.com/yws/res/5178/77736F5ED3AA4F19AD79237D60446616 width=800>
<img src=http://note.youdao.com/yws/res/5181/F53B26560BD54085AA0376B58BCB9CCD width=800>
<img src=http://note.youdao.com/yws/res/5183/FBD062EC6D7F4696AEE70CF40F688EB2 width=800>
<img src=http://note.youdao.com/yws/res/5185/B5B96A5A94DB4E7B8CE47CD432DB9242 width=800>
<img src=http://note.youdao.com/yws/res/5187/856E11B474624254AFF8809FD0D40B18 width=800>
<img src=http://note.youdao.com/yws/res/5189/6E565BB2158A4DB185D90008F1B56778 width=800>
<img src=http://note.youdao.com/yws/res/5191/7F4689D1CE2B4EA98E7B389BD7362E75 width=800>