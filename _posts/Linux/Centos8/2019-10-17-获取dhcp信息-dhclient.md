---
title: 获取dhcp信息-dhclient
date: 2019-10-17 09:49:00
tags: ["系统", "Linux"]
categories: ["Linux", "Centos8"]
render_with_liquid: false
permalink: /posts/2019-10-17-获取dhcp信息-dhclient/
---
> 由于centos8 调整了dhcp的信息，不在将网卡独立出每个单独的dhcp文件，需要独立来进行处理

> https://www.linuxcool.com/dhclient

## dhclient命令

dhclient 命令的作用是：使用动态主机配置协议动态的配置网络接口的网络参数，也支持BOOTP协议

* *语法格式：** dhclient [参数] [网络接口]
* *常用参数：**
| 参数 | 描述 |
| --- | --- |
| - p | 指定dhcp客户端监听的端口号(默认端口号86) |
| - d | 总是以前台方式运行程度 |
| - q | 安静模式，不打印任何错误的提示信息 |
| - r | 释放ip地址 |
| - n | 不配置任何接口 |
| - x | 停止正在运行的dhcp客户端，而不释放当前租约，杀死现有的dhclient |
| - s | 在获取ip地址之前指定dhcp服务器 |
| - w | 即使没有找到广播接口，也继续运行 |

## 参数实例

## 在指定网络接口上发出dhcp请求

```json
[root@linux ~]# dhclient eth0

```

释放ip地址：

```json
[root@linux ~]# dhclient -r
Killed old client process

```

从指定的服务器获取ip地址：

```json
[root@linux ~]# dhclient -s 192.168.60.240

```

停止运行dhclient：

```json
[root@linuxcool ~]# dhclient -x
Killed old client process

```

## 双网卡获取地址示例

> 由于需要固定IP地址，需要独立对网卡获取dhcp信息

释放ip并显示状态信息

```bash
[root@linux ~]# dhclient -r -v

# 或直接释放ip地址

[root@linux ~]# dhclient -r

```

删除dhcp文件

```bash
[root@linux ~]# rm -f /var/lib/dhclint/dhclient.leases

# centos8 只存在一个文件，不删除会存在多个网卡信息

```

获取指定网卡的dhcp信息

```json
[root@linux ~]# dhclient -v eth0

```

查看dhcp详细信息

```bash
cat /var/lib/dhclint/dhclient.leases

# 获取ip、子网、网关：

# dhcpfile=/var/lib/dhclint/dhclient.leases

# IP=`cat $dhcpfilee|grep -w 'fixed-address'|awk '{print $2}'|sed 's/;//'`

# NETMASK=`cat $dhcpfile|grep -w 'option subnet-mask'|awk '{print $3}'|sed 's/;//'`

# GATEWAY=`cat $dhcpfile|grep -w 'option routers'|awk '{print $3}'|sed 's/;//'`

```
