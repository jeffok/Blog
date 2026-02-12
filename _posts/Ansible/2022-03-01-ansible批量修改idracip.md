---
title: ansible批量修改idracip
date: 2022-03-01 11:15:00
tags: ["自动化", "Ansible"]
categories: ["Ansible"]
render_with_liquid: false
permalink: /posts/2022-03-01-ansible批量修改idracip/
---

本文档介绍如何使用 Ansible 批量修改服务器的 iDRAC IP 地址。

## 主机清单配置

创建主机清单文件 `host.ini`，为每台服务器配置物理 IP 和对应的 iDRAC IP：

```ini
[all]

# phy_ip 对应物理 IP，IDracIP 对应 iDRAC IP

172.19.32.107  IDracIP=10.19.32.107
172.19.32.108  IDracIP=10.19.32.108

```

## Playbook 配置

创建 playbook 文件 `change_ip.yml`：

```yaml
---
- name: Change IDracIP
  hosts: all
  remote_user: root
  gather_facts: false
  vars:
    IDracMASK: 1.2.3.4  # 子网掩码
    IDracIPGW: 10.19.32.254   # 网关地址
  tasks:
    - name: Change IDracIP
      ansible.builtin.raw: >-
        ipmitool lan set 1 ipaddr {{ IDracIP | quote }} &&
        ipmitool lan set 1 netmask {{ IDracMASK | quote }} &&
        ipmitool lan set 1 defgw ipaddr {{ IDracIPGW | quote }}

```

说明：
- 使用 `ipmitool` 命令修改 iDRAC 网络配置
- `lan set 1` 表示设置 LAN 通道 1
- `ipaddr`：设置 IP 地址
- `netmask`：设置子网掩码
- `defgw ipaddr`：设置默认网关

## 运行 Playbook

执行 playbook：

```bash
ansible-playbook change_ip.yml -k    # -k 参数提示输入 SSH 密码

```

> **注意**：确保目标服务器已安装 `ipmitool` 工具，并且有权限执行 iDRAC 配置命令。
