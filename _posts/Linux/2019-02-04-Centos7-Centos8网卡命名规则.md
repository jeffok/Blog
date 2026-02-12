---
title: Centos7、Centos8网卡命名规则
date: 2019-02-04 18:34:00
tags: ["系统", "内核", "Linux"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2019-02-04-Centos7-Centos8网卡命名规则/
---

## 修改方法

> https://www.aikaiyuan.com/12535.html

安装依赖

```bash
yum install initscripts biosdevname

```

1. 修改`/etc/default/grub` <br>
2. 在`GRUB_CMDLINE_LINUX`后面添加如下参数：<br>
    1. 需要em[id]添加 `net.ifnames=1 biosdevname=1`
    2. 需要eth[id]添加`net.ifnames=0 biosdevname=0`
    3. 需要enp0s2 添加 `net.ifnames=1 biosdevname=0` <br>

3. 重新生成image `grub2-mkconfig -o /boot/grub2/grub.cfg`
4. 重启

```ini
GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet net.ifnames=1 biosdevname=1"

```

自定义固定网卡名称,eth0、ens7

```bash
在/etc/udev/rules.d 目录中创建rules文件
vim 70-persistent-net.rules

SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="52:54:00:69:4f:09", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="d6:46:07:6c:2c:ba", ATTR{type}=="1", KERNEL=="ens*", NAME="ens7"

```
