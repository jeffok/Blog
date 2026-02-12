---
title: Linux 系统挂载 NFS 文件系统及性能调整
date: 2022-07-24 05:07:24
tags: [Linux, nfs]
categories: [技术]
---

# 前言
* [相关博文]()
* [个人博客首页](https://jeffok.com)

---

# 操作步骤

## 1. 安装 NFS 客户端

* 如果您使用 CentOS、Redhat、Aliyun Linux 操作系统，请执行以下命令
    ```bash
    sudo yum install nfs-utils
    ```
* 如果您使用 Ubuntu 或 Debian 操作系统，请执行以下命令
    ```bash
    sudo apt-get update
    sudo apt-get install nfs-common
    ```

## 2. 增加同时发起的 NFS 请求的数量

* 请执行以下命令，将同时发起的 NFS 请求数量修改为 128。
    ```bash
    if (lsmod | grep sunrpc); then
    (modinfo sunrpc | grep tcp_max_slot_table_entries) && sysctl -w sunrpc.tcp_max_slot_table_entries=128
    (modinfo sunrpc | grep tcp_slot_table_entries) && sysctl -w sunrpc.tcp_slot_table_entries=128
    fi
    (modinfo sunrpc | grep tcp_max_slot_table_entries) && echo "options sunrpc tcp_max_slot_table_entries=128" >> /etc/modprobe.d/alinas.conf
    (modinfo sunrpc | grep tcp_slot_table_entries) && echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/alinas.conf
    ```

## 3. 手动挂载 NFS 文件系统

* 挂载 NFS 文件系统

    > 说明：
    > * 推荐您通过 NFS v3 协议挂载文件系统，以获得最佳访问性能。
    > * NFS v4.0 支持文件锁（包括 range lock），如果您需要使用多台 Linux ECS 实例同时修改一个文件，请使用 NFS v4.0 协议挂载文件系统。

* 使用 NFS v3 协议挂载文件系统：
    ```bash
    sudo mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport nfs-server-ip:/ /mnt
    ```
* 使用 NFS v4 协议挂载文件系统：
    ```bash
    sudo mount -t nfs -o vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport nfs-server-ip:/ /mnt
    ```

## 4. 自动挂载 NFS 文件系统

* 使用 NFS v3 协议挂载文件系统
    ```bash
    nfs-server-ip:/ /mnt nfs vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0
    ```
* 使用 NFS v4 协议挂载文件系统：
    ```bash
    nfs-server-ip:/ /mnt nfs vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0
    ```

## 5. 修改同时发起的 NFS 请求数量，提升性能

> NFS 客户端对同时发起的 NFS 请求数量进行了控制，默认编译的内核中此参数值为 2，严重影响性能，建议您将该参数值修改为 128。

* 执行以下命令，将同时发起的 NFS 请求数量修改为 128。
    ```bash
    # 执行完成后重启系统
    echo "options sunrpc tcp_slot_table_entries=128" >> /etc/modprobe.d/sunrpc.conf
    echo "options sunrpc tcp_max_slot_table_entries=128" >>  /etc/modprobe.d/sunrpc.conf
    ```
* 检查是否设置成功
    ```bash
    # 挂载完成后执行，返回 128，则修改成功
    cat /proc/sys/sunrpc/tcp_slot_table_entries
    ```

---

# 参考资料
* [参考资料1]()
* [参考资料2]()

---

# 交个朋友
* [Github](https://github.com/jeffok)
* [Twitter](https://twitter.com/bytesjeff)
* [Telegram](https://t.me/hello_jeff)
