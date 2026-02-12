---
title: openldap+docker+nginx部署
date: 2019-08-01 16:32:00
tags: ["容器", "目录服务", "Docker", "OpenLDAP"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2019-08-01-openldap-docker-nginx部署/
---

本文档介绍 openldap+docker+nginx部署 的相关内容。

```bash
启动容器：
docker run -d --privileged --restart=always --net=host -v /etc/localtime:/etc/localtime -v /etc/resolv-dnsmasq.conf:/etc/resolv.conf -v /etc/openldap/slapd.conf:/etc/openldap/slapd.conf -v /etc/openldap/db/:/etc/openldap/db/ njreg.example.com/sa/openldap-server:20190412

```

---

## openldap server 镜像打包：

```bash
1、安装：
yum install -y openldap openldap-*

# rpm -qa |grep openldap

openldap-servers-sql-2.4.40-13.el7.x86_64
openldap-2.4.40-13.el7.x86_64
openldap-devel-2.4.40-13.el7.x86_64
openldap-servers-2.4.40-13.el7.x86_64
openldap-clients-2.4.40-13.el7.x86_64

yum install -y nscd nss-pam-ldapd nss-* pcre pcre-*

2、配置：
配置admin密码：#  slappasswd -s ldapadm
配置/etc/openldap/slapd.conf

```

## openLDAP配置文件，使用镜像模式，两主N从：

```bash
include /etc/openldap/schema/core.schema
include /etc/openldap/schema/cosine.schema
include /etc/openldap/schema/nis.schema
include /etc/openldap/schema/sudo.schema
include /etc/openldap/schema/inetorgperson.schema
include /etc/openldap/schema/ppolicy.schema
include /etc/openldap/schema/ldapns.schema
allow bind_v2
pidfile /var/run/openldap/slapd.pid
argsfile /var/run/openldap/slapd.args
loglevel 0

TLSCipherSuite HIGH:MEDIUM:+SSLv2
TLSVerifyClient demand
TLSCACertificateFile /etc/openldap/ssl/cacert.pem
TLSCertificateFile /etc/openldap/ssl/srv.crt
TLSCertificateKeyFile /etc/openldap/ssl/srv.key

modulepath /usr/lib64/openldap
moduleload syncprov.la
moduleload dynlist.la
moduleload ppolicy.la
moduleload ppolicy.so

access to attrs=userPassword
    by self write
    by dn="uid=repl,ou=Admins,dc=example,dc=com" read
    by anonymous auth

access to attrs=shadowLastChange,gecos,loginShell
    by self write
    by dn="uid=repl,ou=Admins,dc=example,dc=com" read
    by * read

access to *
    by self write
    by dn.exact="cn=monitor,ou=Admins,dc=example,dc=com" write
    by * read

database mdb
maxsize 4294967296
suffix "dc=example,dc=com"
rootdn "cn=admin,ou=Admins,dc=example,dc=com"
rootpw {SSHA}qnZyDwyMukzfycnZCBtaUqV0TmqTw65E
directory /etc/openldap/db/
index objectClass eq
index cn,uid eq
index uidNumber eq
index gidNumber,memberUid eq
index sudoUser eq,sub
index entryCSN eq
index entryUUID eq
index uniqueMember eq

overlay ppolicy
overlay syncprov
overlay     dynlist
dynlist-attrset inetOrgPerson labeledURI
ppolicy_default "cn=default,ou=policy,dc=example,dc=com"
ppolicy_hash_cleartext
syncprov-checkpoint 100 10
syncprov-sessionlog 100
timelimit unlimited
sizelimit unlimited
serverID 1
syncrepl rid=1
        provider=ldaps://njldap02.example.com
        bindmethod=simple
        binddn="uid=repl,ou=Admins,dc=example,dc=com"
        credentials=YOUR_PASSWORD
        searchbase="dc=example,dc=com"
        filter="(objectClass=*)"
        scope=sub
        schemachecking=off
        type=refreshAndPersist
        retry="60 +"
MirrorMode on
database monitor

```

## 检测openldap配置文件及修改启动服务，只启用636端口。

```bash
# vim /etc/openldap/check_config.sh

# !/bin/bash

ldap_pid=$(ps aux |grep slapd|grep -v "grep"|awk '{print $2}')
if [ -n "$ldap_pid" ];then
  kill $ldap_pid
fi

cd /etc/openldap/
rm -fr slapd.d/*
slaptest -f ./slapd.conf -F slapd.d
chown -R ldap:ldap slapd.d/*
chown -R ldap:ldap db

# vim /usr/lib/systemd/system/slapd.service

.
.
.
[Service]
Type=forking
ExecStartPre=/etc/openldap/check_config.sh
ExecStart=/usr/sbin/slapd -u ldap -h ldaps:///
.
.
.

```
