---
title: create_net_qos
date: 2024-01-13 16:08:00
tags: ["网络", "云计算", "OpenStack", "Kolla"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2024-01-13-create_net_qos/
---

本文档介绍 create_net_qos 的相关内容。

```bash
# !/bin/bash

# create qos policy and rule

# # echo "scale=2;((1.5*3)/8)*1000000"|bc|sed "s/\..*//g"

source /etc/kolla/admin-openrc.sh

read -p '请输入最大速率( 如1G:1)  :' PEAK
BURST=`echo "scale=2;((($PEAK*3)/8))"|bc`

openstack network qos policy create p_"$PEAK"_bw_limiter

POLID=`openstack network qos policy show p_"$PEAK"_bw_limiter -f json|jq -r '.id'`

BU=`echo "scale=2;(($BURST*1000000))"|bc|sed "s/\..*//g"`
PE=`echo "scale=2;(($PEAK*1000000))"|bc|sed "s/\..*//g"`

openstack network qos rule create --type bandwidth-limit --max-kbps $PE --max-burst-kbits $BU --egress $POLID
openstack network qos rule create --type bandwidth-limit --max-kbps $PE --max-burst-kbits $BU --ingress $POLID

```
