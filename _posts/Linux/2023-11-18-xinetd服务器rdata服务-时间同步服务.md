---
title: xinetd服务器rdata服务（时间同步服务）
date: 2023-11-18 08:12:00
tags: ["系统", "Linux"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2023-11-18-xinetd服务器rdata服务-时间同步服务-/
---
配置多台服务器时，经常需要让各个服务器之间的时间保持同步，如果服务器有外网环境，可以直接同外部的时间服务器更新时间，可以采用rdate命令更新时间:

```text
rdate -s ﻿tick.greyware.com

```

可以写个脚本放在/etc/cron.hourly中每小时校正一下时间。

如果是内网环境下，可以自己配置一个时间服务器，以CentOS为例，配置时间服务器的方法如下：

1. 先安装xinetd : `yum install -y xinetd  `        （关于xinetd的服务有更详细的介绍：http://blog.csdn.net/cymm_liu/article/details/9372255）

2. 修改`/etc/xinetd.d/time-stream`(tcp), 修改：

disable     = yes  改为

disable = no

3. 启动xinetd

```text
service xinetd start

```

这样其它机器就可以通过rdate 与该机器进行时间同步

```json
[root@rac2]#   rdate -s ip         ——ip是实际rdate服务器的IP

```

4. 为了实时同步，我们写到crontab里，每分钟执行一次：

```json
[root@rac2]# crontab -e

编辑里添加如下行：

* /1 * * * * rdate -s 192.168.15.101

保存退出.

```

我专门测试了一些第2步：如果我设置：disable = yes 重启xinetd服务。再从另一台机器上执行：[root@rac2 etc]# rdate -s 192.168.15.101        ——此ip就是rdate服务器IP。
rdate: couldn't connect to host 192.168.15.101: Connection refused

再设回no：[root@rac2 etc]# rdate -s 192.168.15.101
[root@rac2 etc]#