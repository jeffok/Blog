---
title: centos8 nmcli网卡操作
date: 2019-11-26 13:29:00
tags: ["Linux", "网络", "DNS", "系统", "Mac"]
categories: ["Linux", "Centos8"]
render_with_liquid: false
permalink: /posts/2019-11-26-centos8-nmcli网卡操作/
---
> https://www.jianshu.com/p/3dd5e4ca4b7d nmcli命令集配置
> https://blog.51cto.com/groot/1847482 网络配置
> https://blog.csdn.net/weixin_33728708/article/details/91678868 创建bound team bridge
> https://developer.gnome.org/NetworkManager/stable/nmcli.html nmcli 文档
> https://developer.gnome.org/NetworkManager/stable/nmcli-examples.html nmcli 官方示例

```bash
# 新创建一个br-int的连接

nmcli connection add type bridge con-name br-int ifname br-int ipv4.method manual ipv4.addresses 192.168.88.232/24 gw4 192.168.88.254

# 将网卡加入bridge中

nmcli connection add type bridge-slave ifname enp0s5 master br-int
nmcli connection add type bridge-slave ifname enp0s6 master br-int  （两块同时加入）

# 激活br-int 连接

nmcli connection up br-int

# 删除连接及配置文件

nmcli connection delete enp0s5

# 断开连接

nmcli connection down enp0s5

# 修改ip及网关

nmcli connection modify br-int ipv4.method manual ipv4.addresses 192.168.88.232/24 gw4 192.168.88.254

```

```sql
显示所有网络连接：nmcli con show
显示活动网络连接：nmcli con show -active
显示指定网络连接的详情：nmcli con show eno16777728
显示网络设备连接状态：nmcli dev status
显示所有网络设备的详情：nmcli dev show
显示指定网络设备的详情：nmcli dev show eno16777728

启用网络连接：nmcli con up eno16777728
停用网络连接（可被自动激活）：nmcli con down eno33554960
禁用网卡，防止被自动激活：nmcli dev dis eth0
删除网络连接的配置文件：nmcli con del eno33554960
重新加载配置网络配置文件：nmcli con reload

动态获取IP方式的网络连接配置：nmcli con add con-name eno16777728 type ethernet ifname eno16777728
指定静态IP方式的网络连接配置：nmcli con add con-name eno16777728 ifname eno16777728 autoconnect yes type ethernet ip4 10.1.254.254/16 gw4 10.1.0.1

启用/关闭所有的网络连接：nmcli net on/off
禁用网络设备并防止自动激活：nmcli con dis eno33554960
查看添加网络连接配置的帮助：nmcli con add help

修改网络连接单项参数
nmcli con mod IF-NAME connection.autoconnect yes修改为自动连接
nmcli con mod IF-NAME ipv4.method manual | dhcp修改IP地址是静态还是DHCP
nmcli con mod IF-NAME ipv4.addresses “172.25.X.10/24 172.25.X.254”修改IP配置及网关
nmcli con mod IF-NAME ipv4.gateway 10.1.0.1修改默认网关
nmcli con mod IF-NAME +ipv4.addresses 10.10.10.10/16添加第二个IP地址
nmcli con mod IF-NAME ipv4.dns 114.114.114.114添加dns1
nmcli con mod IF-NAME +ipv4.dns  8.8.8.8添加dns2
nmcli con mod IF-NAME -ipv4.dns  8.8.8.8删除dns

nmcli命令修改所对应的文件条目
nmcli con mod           ifcfg-* 文件
ipv4.method manual       BOOTPROTO=none
ipv4.method auto         BOOTPROTO=dhcp
connection.id eth0        NAME=eth0
(ipv4.addresses          IPADDR0=1.2.3.4
“1.2.3.4/24           PREFIX0=24

192. 0.2.254”)           GATEWAY0=1.2.3.4
ipv4.dns 1.2.3.4        DNS0=1.2.3.4
pv4.dns-search example.com   DOMAIN=example.com
pv4.ignore-auto-dns true    PEERDNS=no
connection.autoconnect yes   ONBOOT=yes
connection.interface-name eth0 DEVICE=eth0
802-3-ethernet.mac-address... HWADDR=...

```

```text
nmcli 修改网络信息
用法：nmcli connection modify { 参数 | help }

参数 := [id | uuid | path] <ID> ([+|-]<设置>.<属性> <值>)+

修改连接配置集的一个或多个属性。配置集由其名称、UUID 或 D-Bus 路径来确定。对
于具有多个值的属性，您可以在属性名称前插入可选的 "+" 或 "-"。"+" 符号允许附加项
而不是覆盖整个值。"-" 符号允许删除选中项而不是整个值。

示例：
nmcli con mod home-wifi wifi.ssid rakosnicek
nmcli con mod em1-1 ipv4.method manual ipv4.addr "192.168.1.2/24, 10.10.1.5/8"
nmcli con mod em1-1 +ipv4.dns 1.2.3.4
nmcli con mod em1-1 -ipv4.dns 1
nmcli con mod em1-1 -ipv6.addr "abbe::cafe/56"
nmcli con mod bond0 +bond.options mii=500
nmcli con mod bond0 -bond.options downdelay

```
