---
title: HUAWEI ACCESS
date: 2021-02-04 11:15:00
tags: ["VPN", "网络", "VLAN"]
categories: ["Network"]
render_with_liquid: false
permalink: /posts/2021-02-04-HUAWEI-ACCESS/
---

本文档介绍 HUAWEI ACCESS 的相关内容。

```bash
lldp enable

#
ip vpn-instance manage

 ipv4-family
  route-distinguisher 150:1
  vpn-target 150:1 export-extcommunity
  vpn-target 150:1 import-extcommunity

interface MEth0/0/0
 ip binding vpn-instance manage
 ip address 192.168.150.246  1.2.3.4

ip route-static vpn-instance manage 0.0.0.0 0.0.0.0 192.168.150.254

stp mode rstp
 telnet server disable
 y

 aaa
  undo local-user policy security-enhance
  local-user suserz password irreversible-cipher P3KK4360Gl687mU=
  local-user suserz service-type ssh terminal
  local-user suserz level 3
  quit

  stelnet server enable
  ssh user suserz authentication-type password
  ssh user suserz service-type stelnet

   user-interface vty 0 4
   authentication-mode aaa
   protocol inbound ssh

   user-interface con 0
   authentication-mode aaa
   quit

dfs-group 1
 priority 120
 source ip 192.168.150.246 vpn-instance manage  peer 192.168.150.247
 quit

#
stp mode rstp

stp v-stp enable
stp bpdu-protection
stp flush disable

#
interface Eth-Trunk0

 mode lacp-dynamic
 trunkport 40GE1/0/1
 trunkport 40GE1/0/2
 undo stp enable
 peer-link 1
 port vlan exclude 1
#
vlan batch  1150 1151 1152

interface Eth-Trunk 101
DES TO-UPLINK-5&6-46-47U-CE8861
port link-type trunk
undo port trunk allow-pass vlan 1
 trunkport 40GE1/0/3
 trunkport 40GE1/0/4
port trunk allow-pass vlan 1150 1151
mode lacp-static
dfs-group 1 m-lag 101
lacp timeout fast
stp disable

interface Eth-Trunk 102
des TO-DOWNLINK-2-47U-S5720
port link-type trunk
undo port trunk allow-pass vlan 1
trunkport 10GE1/0/48
port trunk allow-pass vlan 1151
mode lacp-static
dfs-group 1 m-lag 102
lacp timeout fast
stp disable

commi

```
