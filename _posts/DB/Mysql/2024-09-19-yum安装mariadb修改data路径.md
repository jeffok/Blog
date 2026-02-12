---
title: yum安装mariadb修改data路径
date: 2024-09-19 14:18:00
tags: ["MySQL", "数据库", "MariaDB"]
categories: ["DB", "Mysql"]
render_with_liquid: false
permalink: /posts/2024-09-19-yum安装mariadb修改data路径/
---

本文档介绍 yum安装mariadb修改data路径 的相关内容。

```bash
## 创建数据存储目录

sudo mkdir /home/mariadb

## 同步MariaDB默认文件路径

## 使用rsync -av 可以复制权限等信息，节省步骤

sudo rsync -av /var/lib/mysql /home/mariadb/

```

```bash
# 编辑my.cnf更改datadir目录

# This group is read both both by the client and the server

# use it for options that affect everything

#
[client-server]

#

# include all files from the config directory

#
[mysqld]

datadir=/home/mariadb
socket=/home/mariadb/mysql.sock
[client]
port=3306
socket=/home/mariadb/mysql.sock
!includedir /etc/my.cnf.d

```

> 允许访问Home目录（默认不允许）

```bash
[root@MyCloudServer nginx]# vim /usr/lib/systemd/system/mariadb.service

## 更改第56行 为false

# Prevent accessing /home, /root and /run/user

ProtectHome=false

```
