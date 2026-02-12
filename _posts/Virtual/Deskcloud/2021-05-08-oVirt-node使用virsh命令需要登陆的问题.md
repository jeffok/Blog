---
title: oVirt node使用virsh命令需要登陆的问题
date: 2021-05-08 14:18:00
tags: ["虚拟化", "oVirt"]
categories: ["Virtual", "Deskcloud"]
render_with_liquid: false
permalink: /posts/2021-05-08-oVirt-node使用virsh命令需要登陆的问题/
---

本文档介绍 oVirt node使用virsh命令需要登陆的问题 的相关内容。

```bash
如果要在oVirt的node使用virsh命令管理查看虚拟机，会有要求输入用户名。

[root@node2 ~]# virsh list --all
Please enter your authentication name: admin
Please enter your password:
YOUR_PASSWORD failed to connect to the hypervisor
error: no valid connection
error: authentication failed: authentication failed

这个主要是因为oVirt管理节点和计算节点使用tls证书认证，之间的通讯进行加密。通过saslpasswd2命令创建一个用户就可以，在virsh的命令中，输入用户，密码，就可以像以前一样使用了。

[root@node2 ~]# saslpasswd2 -a libvirt admin
Password:
YOUR_PASSWORD (for verification):
[root@node2 ~]# virsh list --all
Please enter your authentication name: admin
Please enter your password:
 Id    Name                           State

---------------------------------------------------
 3     test05                         running

```
