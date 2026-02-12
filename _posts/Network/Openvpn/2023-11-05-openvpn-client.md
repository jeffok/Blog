---
title: openvpn client
date: 2023-11-05 13:29:00
tags: ["VPN", "网络", "OpenVPN"]
categories: ["Network", "Openvpn"]
render_with_liquid: false
permalink: /posts/2023-11-05-openvpn-client/
---

## openvpn client配置

> 需要安装epel源 yum install epel*

## 安装openvpn

```bash
yum install openvpn -y

```

## 客户端配置文件client.ovpn证书

```bash
client1
dev tun # 路由模式，跟服务端配置一致
proto tcp # TCP协议，跟服务端配置一致
remote xxx.xxx.xxx.xxx 1194 # openvpn服务端的公网的IP和端口
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client1.crt # 客户端client1的证书文件
key client1.key # 客户端client1的密钥文件
remote-cert-tls server
tls-auth ta.key 1
comp-lzo
verb 3

```

## 将上面的文件都上传到/etc/openvpn/目录下然后日志输出到/var/log/openvpn.log 后台启动命令（注意证书文件）

```bash
openvpn --daemon --cd /etc/openvpn --config client.ovpn --log-append /var/log/openvpn.log
openvpn \
-daemon \
-cd /etc/openvpn \
-config client.ovpn \
-auth-user-pass /etc/openvpn/passwd \
-log-append /var/log/openvpn.log

参数解释

-daemon: openvpn 以daemon方式启动
-cd dir: 配置文件的目录，openvpn初始化前，先切换到些目录。
-config file: 客户端配置文件路径。
-log-append file: 日志文件路径，如果文件不存在会自动创建
可以将上述命令加到/etc/rc.local里开机启动

```
