---
title: OpenStack镜像双网卡自动配置脚本
date: 2022-11-06 09:25:00
tags: ["网络", "云计算", "OpenStack"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2022-11-06-OpenStack镜像双网卡自动配置脚本/
---

本文档介绍 OpenStack镜像双网卡自动配置脚本 的相关内容。

1. 使用NetworkManager
镜像中启动NetworkManager 在添加其它地址时自动配置

如果未启用NetworkManager可以使用下边的方式

首先在/etc/udev/rules.d 创建70-add-eth1.rules和70-del-eth1.rules

```ini
vim /etc/udev/rules.d/70-add-eth1.rules
ACTION=="add", KERNEL=="eth1", SUBSYSTEM=="net", DRIVERS=="", ATTR{type}=="1", PROGRAM="/usr/bin/add_net.sh"

vim /etc/udev/rules.d/70-del-eth1.rules
ACTION=="remove", KERNEL=="eth1", SUBSYSTEM=="net", PROGRAM="/usr/bin/del_net.sh"

```

增加添加网卡的脚本

```bash
# !/bin/bash

# add_net.sh

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/root/bin:/root/bin

# eth0内网,eth1外网

eth0='/etc/sysconfig/network-scripts/ifcfg-eth0'
eth1='/etc/sysconfig/network-scripts/ifcfg-eth1'

# 第一次启动, 交给jgcloud_init执行

if grep "BOOTPROTO=dhcp" $eth0 > /dev/null; then
  exit 0
fi

# 重启时

# 如果已经有固定外网ip,则略过,避免重复执行

if [ -e $eth1 ]; then
  if grep "BOOTPROTO=static" $eth1 > /dev/null; then
    exit 0
  fi
fi

# eth1 外网配置文件

cat > ${eth1} << EOF
TYPE=Ethernet
DEVICE=eth1
BOOTPROTO=dhcp
NM_CONTROLLED=no
PEERDNS=no
ONBOOT=yes
EOF

dhcp_pid=`ps -ef | grep "dhclient--eth1" | awk '{print $1}'`
if [ "x${dhcp_pid}" != "x" ]; then
  kill -9 $dhcp_pid
fi

# 启动eth1, dhcp获取信息

dhcp_file='/var/lib/dhclient/dhclient--eth1.lease'

> $dhcp_file
ifdown eth1
ifup eth1

while :
do
  if cat $dhcp_file | grep "fixed-address" > /dev/null; then
    IPADDR=`grep 'fixed-address' $dhcp_file | awk '{print $2}' | sed 's/;//'`
    NETMASK=`grep 'option subnet-mask' $dhcp_file | awk '{print $3}' | sed 's/;//'`
    GATEWAY=`grep 'option routers' $dhcp_file | awk '{print $3}' | sed 's/;//'`

    dhcp_pid=`ps -ef | grep "dhclient--eth1" | awk '{print $1}'`
    if [ "x${dhcp_pid}" != "x" ]; then
      kill -9 $dhcp_pid
    fi

    break
  fi
  sleep 5
done

# 固化eth1

cat > $eth1 <<EOF
TYPE=Ethernet
DEVICE=eth1
BOOTPROTO=static
NM_CONTROLLED=no
PEERDNS=no
ONBOOT=yes
IPADDR=${IPADDR}
NETMASK=${NETMASK}
GATEWAY=${GATEWAY}
EOF

# 注释eth0网关

sed -i '/^GATEWAY/s/^/#/' $eth0

systemctl restart network

# 添加富丰路由:

# 废弃, 采用jgcloud_init里加入route-eth0里方法

# lan_gw=`cat $eth0 | awk -F'=' '/GATEWAY/{print $2}'`

# if [[ "$lan_gw" != "" ]]; then

#  route add -net 172.16.0.0/16 gw $lan_gw

#  echo "route add -net 172.16.0.0/16 gw $lan_gw" >> /etc/rc.local

# fi

```

增加删除网卡的脚本

```bash
# !/bin/bash

# eth0内网,eth1外网

eth0='/etc/sysconfig/network-scripts/ifcfg-eth0'
eth1='/etc/sysconfig/network-scripts/ifcfg-eth1'

# 删除eth1配置文件

rm -f $eth1

# 取消注释的eth0网关

sed -i '/^#GATEWAY/s/^#//' $eth0

systemctl restart network

# 删除富丰路由

# lan_gw=`cat $eth0 | awk -F'=' '/GATEWAY/{print $2}'`

# if [[ "$lan_gw" != "" ]]; then

#  route del -net 172.16.0.0/16 gw  $lan_gw

#  echo "route add -net 172.16.0.0/16 gw $lan_gw" >> /etc/rc.local

#  sed -i "/${lan_gw}/d" /etc/rc.d/rc.local

# fi

```
