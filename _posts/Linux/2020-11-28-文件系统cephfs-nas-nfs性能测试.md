---
title: 文件系统cephfs+nas+nfs性能测试
date: 2020-11-28 09:37:00
tags: ["系统", "Linux", "RedHat"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2020-11-28-文件系统cephfs-nas-nfs性能测试/
---
* 如果您使用CentOS、Redhat、Aliyun Linux等操作系统，运行以下命令。

```bash
  sudo yum install fio

```

* 如果您使用Ubuntu或Debian操作系统，运行以下命令。

```sql
  sudo apt-get  update
  sudo apt-get install fio

```

下面提供一些通用的性能测试样例。

* 随机读IOPS设置

```bash
  fio -numjobs=1 -iodepth=128 -direct=1 -ioengine=libaio -sync=1 -rw=randread -bs=4K -size=1G -time_based -runtime=60 -name=Fio -directory=/mnt

```

* 随机写IOPS设置

```bash
  fio -numjobs=1 -iodepth=128 -direct=1 -ioengine=libaio -sync=1 -rw=randwrite -bs=4K -size=1G -time_based -runtime=60 -name=Fio -directory=/mnt

```

* 随机读吞吐

```bash
  fio -numjobs=1 -iodepth=128 -direct=1 -ioengine=libaio -sync=1 -rw=randread -bs=1M -size=1G -time_based -runtime=60 -name=Fio -directory=/mnt

```

* 随机写吞吐

```bash
  fio -numjobs=1 -iodepth=128 -direct=1 -ioengine=libaio -sync=1 -rw=randwrite -bs=1M -size=1G -time_based -runtime=60 -name=Fio -directory=/mnt

```
