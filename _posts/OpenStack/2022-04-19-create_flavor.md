---
title: create_flavor
date: 2022-04-19 18:34:00
tags: ["Kolla", "云计算", "OpenStack", "脚本", "Bash"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2022-04-19-create_flavor/
---

本文档介绍 create_flavor 的相关内容。

```bash
# !/bin/bash

source /etc/kolla/admin-openrc.sh

# Create flavor

read -p '请输入CPU核数( 如8核:8 )   :'  VCPU
read -p '请输入内存大小( 如1G：1 )   :'  RAM
read -p '请输入硬盘大小( 如1G：1 )   :'  DISK
read -p '请输入最大速率( 如1G: 1 )   :'  PEAK

META="--property hw:cpu_policy=dedicated --property hw:cpu_thread_policy=prefer"

BURST=`echo "scale=2;((($PEAK*3)/8))"|bc`
BU=`echo "scale=2;(($BURST*1000000))"|bc|sed "s/\..*//g"`
PE=`echo "scale=2;(($PEAK*1000000))"|bc|sed "s/\..*//g"`

NET="--property quota:vif_inbound_peak=$PE --property quota:vif_outbound_peak=$PE --property quota:vif_inbound_burst=$BU --property quota:vif_outbound_burst=$BU --property quota:cpu_period=1000000 --property quota:cpu_quota=500000"

RAM_GB=$((RAM*1024))

# echo "--vcpus $VCPU --ram $RAM_GB --disk $DISK g_${VCPU}u${RAM}g${DISK}GB"

# openstack flavor create --vcpus $VCPU --ram $RAM_GB --disk $DISK $NET g_${VCPU}u${RAM}g${DISK}GB

openstack flavor create --vcpus $VCPU --ram $RAM_GB --disk $DISK $META $NET c_${VCPU}u${RAM}g${DISK}GB

# openstack flavor create --vcpus $VCPU --ram $RAM_GB --disk $DISK $META $NET --property "pci_passthrough:alias"="nvme0n1:1" cn_${VCPU}u${RAM}g${DISK}GB

```
