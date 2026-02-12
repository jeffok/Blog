---
title: centos创建企业内部repo
date: 2019-01-26 09:25:00
tags: ["CentOS", "Linux", "Shell", "备份"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2019-01-26-centos创建企业内部repo/
---
> https://www.jianshu.com/p/6c3090968d71

## centos7 通过reposync 搭建本地yum源

使用yum repolist 验证repo文件是否生效

```bash
[root@hkdev data]# yum repolist
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
repo id                                  repo name
base/7/x86_64                            CentOS-7
ceph-nautilus                            ceph-nautilus
docker-ce-stable/x86_64                  Docker CE Stable - x86_64
epel/x86_64                              Extra Packages for Enterprise
extras/7/x86_64                          CentOS-7
kernel                                   kernel
openresty/7/x86_64                       Official OpenResty Open Source
updates/7/x86_64                         CentOS-7
webtatic/x86_64                          Webtatic Repository EL7 - x86_64

```

同步repo文件中的包

```bash
reposync -n --repoid=ceph-nautilus --repoid=kernel -p /data/website/centos/6
reposync -n --repoid=epel/x86_64 -p /data/website/epel/

# -n 只同步最新版本，如果首选同步去掉-n

reposync --repoid=ceph-nautilus --download-metadata -p ./nautilus/x86_64

```

## 手动下载

```ini
wget -m -c -np -nH --cut-dirs=4 -e robots=off https://mirrors.aliyun.com/centos/7.4.1708/cloud/x86_64/openstack-newton/ -P /data/repos/openstack/

```

## kernel 4.19 内核下载

```bash
for i in `curl -L https://mirrors.aliyun.com/centos-altarch/7/kernel/x86_64/Packages/ |awk -F "=\"" '{print $2}'|grep rpm|awk -F "\">" '{print $1}'`;do wget https://mirrors.aliyun.com/centos-altarch/7/kernel/x86_64/Packages/$i ;done

```

## rsync 同步

```bash
# !/bin/bash

# openstack rsync

nfjd_openstack_rsync(){
  Logfile=/Yum/openstack-rsync.log
  Date=`date +"%F %T"`
  echo "${Date} nfjd_rsync" >> ${Logfile}
  sshpass='ssh -o StrictHostKeyChecking=no -p 8220'
  options='-rauv --delete --bwlimit=10000 --timeout=240 root@1.2.3.4'

  rsync --rsh="${sshpass}" ${options}:/Yum/cloud/ /Yum/cloud/ &>> ${Logfile}

  echo '############################################' >> ${Logfile}
}

nfjd_openstack_rsync

# 同步地址：

https://mirrors.tuna.tsinghua.edu.cn/status/#syncing-status

```

## 手动缓存

```bash
# vim /etc/yum.conf

find /var/cache/yum/x86_64/ -name *.rpm -exec cp -a {} /opt/CentOS7.0_liberty_rpm \;

```

## 安装http

```bash
yum -y install httpd -y

```

## 安装软件包

```sql
yum -y install rsync createrepo

```

## 创建目录

```sql
mkdir -p /var/www/repos/centos/7/{os,updates,extras}/x86_64

```

## 设置权限

```bash
chmod -R 755 /var/www/repos

```

## 从清华官方源同步

```sql
# rsync -avz --delete --exclude='repodata' \

rsync://mirrors.tuna.tsinghua.edu.cn/centos/7/os/x86_64/ \
/var/www/repos/centos/7/os/x86_64/

# rsync -avz --delete --exclude='repodata' \

rsync://mirrors.tuna.tsinghua.edu.cn/centos/7/updates/x86_64/ \
/var/www/repos/centos/7/updates/x86_64/

# rsync -avz --delete --exclude='repodata' \

rsync://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/x86_64/ \
/var/www/repos/centos/7/extras/x86_64/

```

## 创建 metadata repositories

```sql
# createrepo /var/www/repos/centos/7/os/x86_64/

# createrepo /var/www/repos/centos/7/updates/x86_64/

# createrepo /var/www/repos/centos/7/extras/x86_64/

```

## 设置定时任务，每天同步

```sql
# vi /etc/cron.daily/update-repo

# !/bin/bash

VER='7'
ARCH='x86_64'
REPOS=(os updates extras)
for REPO in ${REPOS[@]}
do
        rsync -avz --delete --exclude='repodata' \
        rsync://mirrors.tuna.tsinghua.edu.cn/centos/${VER}/${REPO}/${ARCH}/ /var/www/repos/centos/${VER}/${REPO}/${ARCH}/
        createrepo /var/www/repos/centos/${VER}/${REPO}/${ARCH}/
done

```

## 赋予权限

```bash

# chmod 755 /etc/cron.daily/update-repo

```

## 配置httpd主机使其他客户端访问

```bash
# vim /etc/httpd/conf.d/repos.conf

Alias /repos /var/www/repos
<directory /var/www/repos>
        Options +Indexes
        Require all granted
</directory>

```

## 重启服务

```bash

# systemctl restart httpd

```

## 配置防火墙

```bash

# firewall-cmd --add-service=http --permanent # firewall-cmd --reload

```

## 客户机安装内部源

```bash
yum install yum-utils
yum-config-manager --add-repo http://192.168.99.250/repos/xxxxxxx.repo

```

## 客户端的配置文件，其中172.16.8.100是源服务器地址

```ini
# vi /etc/yum.repos.d/CentOS-Base.repo

[base]
name=CentOS-$releasever - Base

# mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra

baseurl=http://172.16.8.100/repos/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-$releasever - Updates

# mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra

baseurl=http://172.16.8.100/repos/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-$releasever - Extras

# mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra

baseurl=http://172.16.8.100/repos/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

```

## nginx 配置

```nginx
server {
        listen  80;
        server_name localhost;
        charset utf-8;

        location / {
          root /data/;
          autoindex on;
          autoindex_exact_size on;
          autoindex_localtime on;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
          proxy_set_header X-Is-EDU   1;
          access_log      logs/repo_access.log main;
          error_log       logs/repo_error.log;
        }

}

```
