---
title: openstack create vip 创建vip
date: 2024-01-14 17:09:00
tags: ["网络", "云计算", "OpenStack"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2024-01-14-openstack-create-vip-创建vip/
---

本文档介绍 openstack create vip 创建vip 的相关内容。

```bash
# !/bin/bash

source /root/sa-openrc

echo -e "\033[33m---------------------Create VIP---------------------\033[0m"
echo -e "\033[36m----------请输入虚拟机IP地址,使用\",\"分隔----------\033[0m"

read -p '请输入IP：' IP  # 172.19.156.52,172.19.156.44

echo -e "\033[36m------------------请选择VIP所在网段------------------\033[0m"
echo -e "\033[36m1. int-app-vlan56\n2. int-db-vlan100\n3. int-dmz-vlan132\n4. int-ops-vlan156\n5. ext-all-131(外网)\033[0m"
read -p "请选择VIP所在网段:" ID

M_IP=`echo $IP|awk -F ',' '{print $1}'`
S_IP=`echo $IP|awk -F ',' '{print $2}'`

# port uuid

M_PORT=`openstack port list |grep $M_IP|awk '{print $2}'`
S_PORT=`openstack port list |grep $S_IP|awk '{print $2}'`

# vip name

N_VIP=`echo $M_IP |awk -F '.' '{print $3"."$4}'`-VIP-`echo $S_IP |awk -F '.' '{print $3"."$4}'`

# 子网与网络必须对应

SUBNET="
20828bf0-eeb0-4da8-b04e-c81fc8090dc0
f3bd8d2b-e950-450b-b742-ef220d224845
88f59ff3-3113-4bc1-8720-120115960674
6868bb64-6571-4356-a8f2-636727b7f763
98d463f4-36be-49ac-b821-1274d982b8f0
"
NETWORK="
1d22bc39-7b8e-4b7d-aa7c-d3815636eaea
c4f60a7f-4209-4bb3-b8be-1c4767a5e948
52d13c94-73eb-4f57-87ec-c063d7478d26
dcfab25b-906a-449a-95e8-a3222e1f1795
b45f7a5f-f7aa-4765-9d79-d9af85a9860d
"

SUB=`echo $SUBNET | xargs | cut -d ' ' -f $ID`
NET=`echo $NETWORK | xargs | cut -d ' ' -f $ID`

echo $SUB
echo $NET

# create vip port

openstack port create --fixed-ip subnet=$SUB --network=$NET $N_VIP

# get vip

VIP=`openstack port list |grep $N_VIP|awk -F "'" '{print $2}'`

# set vip

for i in $M_PORT $S_PORT;do neutron port-update $i --allowed-address-pair ip_address=$VIP

echo "\033[33m----已设置成功，$M_IP,$S_IP的VIP是：$VIP----\033[0m"

```

```bash
# !/bin/bash

source /root/admin-openrc

echo -e "\033[33m---------------------Create VIP---------------------\033[0m"
echo -e "\033[36m----------请输入虚拟机IP地址,使用\"空格\"分隔----------\033[0m"

read -p '请输入IP：' IP # 172.19.156.52 172.19.156.44

echo -e "\033[36m----------VIP的名称\"nginx-proxy-vip\"----------\033[0m"
read -p '请输入IP名称：' NAME # proxy-vip

echo -e "\033[36m------------------请选择VIP所在网段------------------\033[0m"
echo -e "\033[36m1. int-172.17.4.0/22(内网)\n2. ext-1.2.3.4/24(外网)\033[0m"
read -p "请选择VIP所在网段:" ID

# get uuid

for ip in $IP
do
 openstack port list |grep -w $ip|awk '{print $2}' >> /tmp/create_vip.txt
done

# 子网与网络必须对应

SUBNET="
b2f064d0-9270-4c03-acd2-2327fc55dd26
f2c8a063-eb04-4f61-a2e9-ab6218cbac90
"
NETWORK="
424d892b-83d9-4293-b0ac-543788eeac6b
39db70c7-fc3e-4eb5-9de2-89ba8f5d2c09
"
SUB=`echo $SUBNET | xargs | cut -d ' ' -f $ID`
NET=`echo $NETWORK | xargs | cut -d ' ' -f $ID`

# create vip port

openstack port create --fixed-ip subnet=$SUB --network=$NET $NAME
VIP=`openstack port list |grep -w $NAME|awk -F "'" '{print $2}'`

for uuid in `cat /tmp/create_vip.txt`
do
 neutron port-update $uuid --allowed-address-pair ip_address=$VIP
done
rm -rf /tmp/create_vip.txt

echo -e "\033[33m----已设置成功，您的VIP是：$VIP----\033[0m"

```
