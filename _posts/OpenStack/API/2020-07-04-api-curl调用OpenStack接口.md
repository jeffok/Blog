---
title: api-curl调用OpenStack接口
date: 2020-07-04 12:40:00
tags: ["编程", "Python", "云计算", "OpenStack"]
categories: ["OpenStack", "API"]
render_with_liquid: false
permalink: /posts/2020-07-04-api-curl调用OpenStack接口/
---

本文档介绍 api-curl调用OpenStack接口 的相关内容。

## 获取token权限

```bash
curl -i \
H "Content-Type: application/json" \
d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "admin"
        }
      }
    }
  }
}' \
  "http://example.com/v3/auth/tokens" ; echo

```

## 调用OpenStack接口

```bash
curl -s -H "X-Auth-Token: YOUR_TOKEN" \
  http://10.224.100.99:9696/v2.0/ports \
  | python -m json.tool

```
