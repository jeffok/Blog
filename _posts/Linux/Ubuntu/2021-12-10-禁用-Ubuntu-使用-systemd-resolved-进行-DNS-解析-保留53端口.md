---
title: 禁用 Ubuntu 使用 systemd-resolved 进行 DNS 解析，保留53端口
date: 2021-12-10 08:24:00
tags: ["DNS", "Systemd", "网络", "Linux"]
categories: ["Linux", "Ubuntu"]
render_with_liquid: false
permalink: /posts/2021-12-10-禁用-Ubuntu-使用-systemd-resolved-进行-DNS-解析-保留53端口/
---

本文档介绍 禁用 Ubuntu 使用 systemd-resolved 进行 DNS 解析，保留53端口 的相关内容。

## 禁用系统服务

```ini
mkdir -p /etc/systemd/resolved.conf.d/
cat >/etc/systemd/resolved.conf.d/98-disable-127-53.conf << EOF
[Resolve]
DNSStubListener=no
EOF
systemctl daemon-reload && systemctl restart systemd-resolved.service && systemctl status -l systemd-resolved.service --no-pager

```

## 指定dns

```ini
mkdir -p /etc/systemd/resolved.conf.d/
cat >/etc/systemd/resolved.conf.d/99-dns.conf << EOF
[Resolve]
DNS=1.2.3.4 1.2.3.4
DNSStubListener=no
EOF
ln -s -f /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl daemon-reload && systemctl restart systemd-resolved.service && systemctl status -l systemd-resolved.service --no-pager
cat /etc/resolv.conf

```
