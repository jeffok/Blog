---
title: 自建 PowerDNS 作为权威 DNS 服务器
date: 2022-07-16 10:02:00
tags: ["数据库", "网络", "DNS", "MySQL"]
categories: ["Network", "DNS"]
render_with_liquid: false
permalink: /posts/2022-07-16-自建-PowerDNS-作为权威-DNS-服务器/
---

## 搭建 PowerDNS

为了方便，我这里直接用 Docker-compose 搭建了

```yaml
version: '2'

services:
  db:
    image: mariadb:latest
    environment:
MYSQL_ALLOW_EMPTY_PASSWORD=YOUR_PASSWORD
MYSQL_DATABASE=powerdnsadmin
MYSQL_USER=pdns
MYSQL_PASSWORD=YOUR_PASSWORD
    ports:
3306:3306
    restart: always
    volumes:
./pda-mysql:/var/lib/mysql
  pdns:
    #build: pdns
    image: pschiffe/pdns-mysql
    hostname: pdns
    domainname: computingforgeeks.com
    restart: always
    depends_on:
db
    links:
"db:mysql"
    ports:
"53:53"
"53:53/udp"
"8081:8081"
    environment:
PDNS_gmysql_host=db
PDNS_gmysql_port=3306
PDNS_gmysql_user=pdns
PDNS_gmysql_dbname=powerdnsadmin
PDNS_gmysql_password=YOUR_PASSWORD
PDNS_master=yes
PDNS_api=yes
PDNS_api_key=YOUR_API_KEY
PDNSCONF_API_KEY=YOUR_API_KEY
PDNS_webserver=yes
PDNS_webserver-allow-from=127.0.0.1,10.0.0.0/8,172.0.0.0/8,1.2.3.4/24
PDNS_webserver_address=0.0.0.0
PDNS_webserver_password=YOUR_PASSWORD
PDNS_version_string=anonymous
PDNS_default_ttl=1500
PDNS_allow_notify_from=0.0.0.0
PDNS_allow_axfr_ips=127.0.0.1

  web_app:
    image: ngoduykhanh/powerdns-admin:latest
    container_name: powerdns_admin
    ports:
"8080:80"
    depends_on:
db
    restart: always
    links:
db:mysql
pdns:pdns
    logging:
      driver: json-file
      options:
        max-size: 50m
    environment:
SQLALCHEMY_DATABASE_URI=mysql://pdns:mypdns@db/powerdnsadmin
GUNICORN_TIMEOUT=60
GUNICORN_WORKERS=2
GUNICORN_LOGLEVEL=DEBUG

```

搭建完成后打开 http://serverip:8080/ 就是你的 PowerDNS Web 界面了
![image](https://note.youdao.com/yws/res/12607/0E6875AE2021469BB8D3CF2A42888E36)

## 使用 PowerDNS 解析自己的域名

然后注册一个账号，第一个账号默认带管理员权限

首先，我们需要去 Settings-> Zone Records 将 SOA 勾选上（很重要）
![image](https://note.youdao.com/yws/res/12611/10FA62F258DF4987942B322C7B154DB9)

之后我们需要去你购买域名的地方添加一个胶水记录，至于什么是胶水记录可以去看 `https://laona.dev/post/glue-record/`

我这里就演示一下我自己的，我的域名是在 Dynadot 买的，可以在`https://www.dynadot.com/zh/account/domain/server/list.html`的右上角点注册域名服务器
![image](https://note.youdao.com/yws/res/12613/E5795C0AC58B452EAFA29AEFD41484CB)

然后将你域名的 NS 改成这个就行了
![image](https://note.youdao.com/yws/res/12615/32F9A38E301446ED808C141EDF8BF80F)

我这里还添加了两个 HE 的服务器，作用我会在之后解释

## 创建主服务器

![image](https://note.youdao.com/yws/res/12617/0FC6CEBA91484A238264480B340B4756)

创建区域后会自动添加 SOA 记录，我们只需要添加 NS 记录就行

![image](https://note.youdao.com/yws/res/12619/42E14596A0764373940FE12EC8BF4BA4)

之后就可以添加自己的 DNS 记录了
![image](https://note.youdao.com/yws/res/12621/6790981019384EABBBC3BA022D086CE7)

## 使用 HE DNS 作为从 DNS 节点

我们自己搭建 DNS 可能会因为各种原因，SLA 会比较低，因此我们还需要一个从 DNS 节点作为备用，这就是我在 NS 记录里添加了 HE DNS 的原因

首先我们需要在 PowerDNS 的配置文件内给 HE 的服务器放行，在首行添加

```ini
allow-axfr-ips=1.2.3.4

```

![image](https://note.youdao.com/yws/res/12624/CC8FAB3A272D486CB50E2933554FE5A4)

然后我们只需要去`https://dns.he.net/`点击 Add a new slave，就可以让 HE DNS 作为从 DNS 节点来同步主 DNS 了，同步频率之类的是通过主 DNS 节点的 SOA 记录来控制的
![image](https://note.youdao.com/yws/res/12627/768D596D226E4D3FA52D6192C30E672F)

记录很快就会同步过来，但是我的记录有一些 LUA 记录，因此可能会有点问题
![image](https://note.youdao.com/yws/res/12629/8BB37C5533944B039F4C317D216F39DC)

## 一点点小尾巴

PowerDNS 还有很多更高级的用法，例如 LUA 脚本和 GEO DNS 什么的，大家可以通过`PowerDNS`的官方文档好好学习一下

https://lala.im/7057.html
https://lantian.pub/article/modify-website/powerdns-lua-diy-geodns.lantian/