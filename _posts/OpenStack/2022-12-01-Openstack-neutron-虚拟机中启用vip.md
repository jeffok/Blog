---
title: Openstack neutron 虚拟机中启用vip
date: 2022-12-01 16:20:00
tags: ["云计算", "OpenStack", "Neutron"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2022-12-01-Openstack-neutron-虚拟机中启用vip/
---
keepalived + allow_address_pairs实现虚拟机高可用

```sql
keepalived实现instance high available（Neutron flat网络模式下）
[root@openstack-1 ~(keystone_admin)]# neutron net-list （找出pub-net的id号）
[root@openstack-1 ~(keystone_admin)]# neutron port-list --netework_id=54f5ea9b-5d05-42e3-995f-c00e6824be25(这个id就是pub-net的id)   查看这个网络下的所有port信息
[root@openstack-1 ~(keystone_admin)]# neutron port-create --fixed-ip ip_address=1.2.3.4(虚拟ip地址) --security-group default pub-net  创建keepalived的vip
[root@openstack-1 ~(keystone_admin)]# neutron port-update  fee2f24e-87a1-4e23-b60b-8d4a33f9257f(这个id是web2的port id) --allowed_address_pairs list=true type=dict ip_address=1.2.3.4
[root@openstack-1 ~(keystone_admin)]# neutron port-update   4082ae4a-5af6-43ea-9370-fa493fb9ad67(这个id是web1的port id)  --allowed_address_pairs list=true type=dict ip_address=1.2.3.4 （这个ip地址就可以被keepavlied当作vip用了）
[root@openstack-1 ~(keystone_admin)]# neutron port-show  4082ae4a-5af6-43ea-9370-fa493fb9ad67  查看信息

```

关闭neutron port的安全组特性

```sql
neutron port-update --no-security-groups $port_id
neutron port-update $port_id --port-security-enabled=False

```

http://www.99cloud.net/html/2016/jiuzhouyuanchuang_1123/256.html

IPVS direct routing on top of OpenStack
http://superuser.openstack.org/articles/ipvs-direct-routing-openstack/

安全组规则  VRRP  VIP 漂移
入口   112   1.2.3.4
出口   112   1.2.3.4

使用LVS  DR模式，需要修改接口信息
界面操作：在可用地址增加网段非IP，如：192.168.88.1/24   不能使用192.168.1.1/32

命令行：

```sql
neutron port-update --allowed-address-pair ip_address=192.168.1.0/24  <port-id>

```
