---
title: Ceph-deploy工具部署Ceph集群
date: 2023-03-03 12:52:00
tags: ["存储", "Ceph", "内核", "Linux"]
categories: ["Ceph"]
render_with_liquid: false
permalink: /posts/2023-03-03-Ceph-deploy工具部署Ceph集群/
---

本文档介绍使用 ceph-deploy 工具部署 Ceph 集群的步骤。

## ceph-deploy 工具部署 ceph 集群

### 1. 安装依赖环境包

```bash
yum install -y yum-utils snappy leveldb gdisk python-argparse gperftools-libs

```

### 2. 调整内核参数

OSD 进程可以产生大量的进程，需要调整内核参数：

```bash
vim /etc/sysctl.conf
kernel.pid_max = 4194303

echo "kernel.pid_max = 4194303" >> /etc/sysctl.conf

```

### 3. 安装工具

```bash
yum install ceph-deploy

建议使用pip安装新版本

如果安装出错，提示python-setuptools的问题，可以使用pip安装
安装pip
yum install python-pip

添加国内pip源
mkdir ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.douban.com/simple/
[install]
trusted-host = pypi.douban.com
EOF

安装（新版本命令有变化）
pip install ceph-deploy==1.5.39

mkdir -p /data/ceph/deploy

```
