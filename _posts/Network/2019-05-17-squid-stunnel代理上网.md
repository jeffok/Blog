---
title: squid + stunnel代理上网
date: 2019-05-17 12:16:00
tags: ["Systemd", "网络", "Linux", "代理"]
categories: ["Network"]
render_with_liquid: false
permalink: /posts/posts/2019-05-17-squid-stunnel代理上网/
---

本文档介绍 squid + stunnel代理上网 的相关内容。

## 安装软件包

```bash
yum -y install squid

```

## 配置监听地址

```bash
vim /etc/squid/squid.conf
...

# Squid normally listens to port 3128

http_port 127.0.0.1:8899    端口为本地代理端口
...

```

## 启动

```bash
systemctl enable squid
systemctl restart squid

```

## 安装stunnel

```bash
# server端

yum install -y stunnel openssl openssl-devel

cd /etc/stunnel
mkdir certs

```

## 生成服务器证书

```text
openssl req -new -x509 -days 3650 -nodes -out server.pem -keyout server.pem

```

## 生成客户端证书

```routeros
openssl req -new -x509 -days 3650 -nodes -out certs/client.pem -keyout certs/client.pem

/etc/pki/tls/misc/c_hash certs/client.pem
9741086f.0 => client.pem   输出

# 将上边输入的结果重命名客户端证书，不然不能进行代理

mv certs/client.pem certs/cf8dae60.0

```

## 查看是否有stunnel用户名和组，如果没有需要创建

```text
groupadd stunnel
useradd stunnel -s /sbin/nologin -M -g stunnel

```

## 并修改/etc/stunnel 目录的权限

```bash
chown -R stunnel.stunnel /etc/stunnel

```

## cat /etc/stunnel/stunnel.conf

```ini
debug = 6

# 用户名

setuid=stunnel

# 用户组

setgid=stunnel
output=/etc/stunnel/stunnel.log
pid=/etc/stunnel/stunnel.pid
cert=/etc/stunnel/server.pem
;客户端证书目录，可以有多个客户端，每个客户端都需要证书
CApath=/etc/stunnel/certs
fips=no
client=no
verify=3
[squid]
;监听1081端口
accept=443
;转发到squid的1080端口
connect=127.0.0.1:8899

```

## 启动

```text
stunnel /etc/stunnel/stunnel.conf

```

## Centos7 启动脚本

```ini
# vim /usr/lib/systemd/system/stunnel.service

[Unit]
Description=SSL tunnel for network daemons
After=syslog.target

[Service]
ExecStart=/bin/stunnel /etc/stunnel/stunnel.conf
ExecStop=kill -9 $(pgrep stunnel)
ExecStatus=pgrep stunnel
Type=forking

[Install]
WantedBy=multi-user.target

```

## 客户端

```ini
[CLIENT]
accept=1080
connect=1.2.3.4:443
client=yes
cert=C:\Program Files (x86)\stunnel\client.pem

##########

# cert = /etc/stunnel/9741086f.0

client=yes
fips = no
output=/etc/stunnel/stunnel.log

# [squid-rjy]

# accept=127.0.0.1:1081

# connect=1.2.3.4:443

# [squid-aliyun]

# accept=127.0.0.1:1082

# connect=1.2.3.4:443

# [hk-devops]

# accept=127.0.0.1:1082

# connect=proxy.xsbloc.com:8443

[xiaoniaoyun]
accept=127.0.0.1:1082
connect=1.2.3.4:443

```

## 后台运行

```text
brew services start stunnel

```

## 前台运行

```text
stunnel

```
