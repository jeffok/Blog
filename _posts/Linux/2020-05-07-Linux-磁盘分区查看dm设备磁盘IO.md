---
title: Linux 磁盘分区查看dm设备磁盘IO
date: 2020-05-07 08:12:00
tags: ["系统", "Linux"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2020-05-07-Linux-磁盘分区查看dm设备磁盘IO/
---
> http://lovesoo.org/linux-sar-command-detailed.html  sar 命令详解

> https://blog.csdn.net/qq_39591494/article/details/78418162  详解mpstat、iostat、sar、vmstat命令的使用

> http://rebootcat.com/2017/12/14/instability-of-cpu/ io 超高分析

## 显示所有磁盘信息

```text
fdisk -l

```

## 查看磁盘io

```text
iotop
iostat -dx
查看磁盘状态时,有的会有如下dm-0,dm-1，jbd2/dm-2-8

```

> 如果在分区时利用了LVM,则一般会生成dm-N 逻辑卷(LogiｃVolume).它类似于普通分区时的一个分区如sda0之类的.只不过它利用了Mapper Device机制,在PysicalVolume上虚拟出来的分区信息

## 查看tps

```text
sar -b 1

```

## 查找dm-N对应的挂载点

```text
sar -d 3 5
cd /dev/mapper; ll

```

## 查看lvm分区对应dm设备

```bash
lvdisplay|awk '/LV Name/{n=$3} /Block device/{d=$3; sub(".*:","dm-",d); print d,n;}'

```
