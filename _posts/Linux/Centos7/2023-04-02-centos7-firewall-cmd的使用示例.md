---
title: centos7 firewall-cmd的使用示例
date: 2023-04-02 12:52:00
tags: ["系统", "Linux"]
categories: ["Linux", "Centos7"]
render_with_liquid: false
permalink: /posts/2023-04-02-centos7-firewall-cmd的使用示例/
---

本文档介绍 centos7 firewall-cmd的使用示例 的相关内容。

```bash
firewall-cmd --list-all             #查看默认zone的规则
firewall-cmd --list-all --zone=<zone>            #查看指定zone的规则
firewall-cmd --list-all-zones   #查看所有zone的规则
firewall-cmd --reload             # 更新规则，不重启服务
firewall-cmd --complete-reload    # 更新规则，重启服务

```

```bash
根据公司网络设置的规则：

systemctl start firewalld.service
systemctl enable firewalld.service

清空规则：

rm -f /etc/firewalld/zones/*

rm -f /etc/firewalld/direct.xml

systemctl restart firewalld.service

firewall-cmd --permanent --remove-service=dhcpv6-client --zone=public  删除

firewall-cmd --permanent --remove-service=ssh --zone=public   删除

firewall-cmd --permanent --add-interface=eth0 --zone=public                             #绑定网卡到public。

firewall-cmd --permanent --add-interface=eth1 --zone=trusted                           #允许所有内网通过。

firewall-cmd --permanent --add-port=8220/tcp --zone=public                             #允许外网访问8220端口。

systemctl restart firewalld.service

```

```bash
# 允许某网段的数据通过：

firewall-cmd --permanent --add-source=172.16.96.0/21 --zone=trusted

# 仅允许某IP段访问本机某端口：

firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="172.16.96.0/21" port protocol="tcp" port="8080" accept"

systemctl restart firewalld.service

# 规则需重启或者reload  firewalld才能生效！

# 高级规则，自定义规则

# 仅允许某IP段访问本机某端口：

firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="172.16.96.0/21" port protocol="tcp" port="8080" accept"

# 直接调用iptables规则方式：

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 -i eth1 -j ACCEPT                       #允许由eth1网卡进来的数据通过

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 -s 1.2.3.4/24 -j ACCEPT     #允许来自某网段的数据通过

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 -p tcp --dport=8220 -j ACCEPT     #允许到某个端口的数据通过

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 -i eth1 -p tcp --dport=8220 -j ACCEPT  #允许8220从eth1进入

# 查看直接iptables的规则：

firewall-cmd --direct --get-rules ipv4 filter INPUT

# 查看iptables规则：

iptables-save

```
