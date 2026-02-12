---
title: routeros 配置usb4g网卡
date: 2022-02-13 19:59:00
tags: ["RouterOS", "网络"]
categories: ["Network", "RouterOS"]
render_with_liquid: false
permalink: /posts/2022-02-13-routeros-配置usb4g网卡/
---

本文档介绍 routeros 配置usb4g网卡 的相关内容。

## huawei e3372 usb 4G lte model

```routeros
# model = RouterBOARD 750G r3

/interface lte
set [ find ] mac-address=0C:5B:8F:27:9A:64 name=lte1
/interface bridge
add fast-forward=no name=bridge-mobile
/interface list
add name=LAN
add name=WAN
/ip pool
add name=dhcp_pool-mobile ranges=192.168.100.2-192.168.100.254
/ip dhcp-server
add address-pool=dhcp_pool-mobile disabled=no interface=bridge-mobile name=dhcp-mobile
/interface bridge port
add bridge=bridge-mobile interface=ether1
add bridge=bridge-mobile interface=ether2
add bridge=bridge-mobile interface=ether3
add bridge=bridge-mobile interface=ether4
add bridge=bridge-mobile interface=ether5
/interface list member
add interface=bridge-mobile list=LAN
add interface=ether1 list=LAN
add interface=ether2 list=LAN
add interface=ether3 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
add interface=lte1 list=WAN
/ip address
add address=192.168.100.1/24 interface=bridge-mobile network=192.168.100.0
/ip dhcp-server network
add address=192.168.100.0/24 gateway=192.168.100.1
/ip firewall filter
add action=fasttrack-connection chain=forward comment="fasttrack-dns tcp" dst-port=53 protocol=tcp
add action=fasttrack-connection chain=forward comment="fasttrack-dns udp" dst-port=53 protocol=udp
add action=accept chain=input comment="Accept established - related - untracked" connection-nat-state="" connection-state=established,related,untracked in-interface-list=WAN
add action=drop chain=input comment="Drop invalid conn" connection-state=invalid in-interface-list=WAN
/ip firewall nat
add action=masquerade chain=srcnat out-interface=lte1
/system routerboard settings
set silent-boot=no

```
