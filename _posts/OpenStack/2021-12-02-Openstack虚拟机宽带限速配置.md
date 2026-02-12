---
title: Openstack虚拟机宽带限速配置
date: 2021-12-02 12:16:00
tags: ["云计算", "OpenStack", "Neutron"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2021-12-02-Openstack虚拟机宽带限速配置/
---
修改Neutron配置文件，让其支持QoS
修改

```ini
neutron.conf
service_plugins = neutron.services.qos.qos_plugin.QoSPlugin

```

修改
/etc/neutron/plugins/ml2/

```ini
ml2_conf.ini
[ml2]
extension_drivers=qos

linuxbridge_agent.ini
[agent]
extensions=qos

```

重启neutron

```bash
systemctl restart neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service

```

创建一个policy

```sql
neutron qos-policy-create bw-limiter
openstack network qos policy create 20u30d

```

添加限速rule

```sql
neutron qos-bandwidth-limit-rule-create bw-limiter --max-kbps 102400 --max-burst-kbps 112640   # 最大100M  突发110M
openstack network qos rule create b67368e8-187b-4777-822c-1af3ed59a59e --max-kbps 20480 --max-burst-kbits 30720 --type bandwidth-limit

```

绑定Port

```sql
neutron port-update <port_id> --qos-policy bw-limiter
openstack port set 32873801-a55c-4656-8147-0dd1b576d75a --qos-policy b67368e8-187b-4777-822c-1af3ed59a59e

```

绑定Network

```sql
neutron net-update <network_id> --qos-policy test

```
