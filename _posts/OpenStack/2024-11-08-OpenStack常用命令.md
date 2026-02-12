---
title: OpenStack常用命令
date: 2024-11-08 10:38:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2024-11-08-OpenStack常用命令/
---

本文档介绍 OpenStack常用命令 的相关内容。

## 查看所有虚拟机列表

```yaml
[root@SXXY-PSC-P9F2-MCORE-PM-OS01-BCEC-06 wangyf(wangyf)]# openstack server list --long -c "ID" -c "Name" -c "Status" -c "Networks" -c "Host" -c "Flavor Name"

+ --------------------------------------+---------------+--------+------------------------+---------------------------------------+-------------------------------------+
| ID                                   | Name          | Status | Networks               | Flavor Name                           | Host                                |

+ --------------------------------------+---------------+--------+------------------------+---------------------------------------+-------------------------------------+
| bcf7ea5b-681e-4d5b-b377-920d971613e7 | wangyf-test01 | ACTIVE | yanwu-test=192.168.0.5 | ecloud-normal-2vcpu-2G-20G-5118-1.0Gb | SXXY-PSC-P9F2-SPOD1-PM-OS01-BCEC-52 |

+ --------------------------------------+---------------+--------+------------------------+---------------------------------------+-------------------------------------+

```

## nova boot 指定创建虚拟机

```bash
nova boot szbwx-sa-mysql-sysmon02 \

-flavor gn_16u64g40GB \
-nic net-id=3949abd0-9a52-48d9-bb54-74326a4dbf16 \
-availability-zone szbwx-az-int:szbwx-cloud-opsnode-T08-06-0826.example.com \
-block-device id=53b9dff6-b93d-47bb-84b0-86a05399dd53,source=image,dest=volume,device=vda,size=40,bootindex=0,shutdown=remove,volume_type=sas

# --flavor 虚拟机配置 name 或 uuid

# --nic net-id 网络uuid

# --availability-zone 可用域名:主机名

# --block-device  磁盘配置

    # id 镜像的uuid
    # source 创建方式，即源为什么
    # dest 目标
    # size 磁盘大小
    # bootindex 0支持启动，1不支持启动
    # shutdown 删除虚拟机是否删除磁盘
    # volume_type 后端磁盘类型

```

## 创建flavor

```sql
https://docs.openstack.org/api-ref/compute/?expanded=create-flavor-detail,create-extra-specs-for-a-flavor-detail

```

## OpenStack Flavor 磁盘限速

```sql
openstack flavor set $i \

-property quota:read_bytes_sec=419430400 \
-property quota:write_bytes_sec=314572800 \
-property quota:read_iops_sec=10000 \
-property quota:write_iops_sec=3000

```

## OpenStack Flavor 网络限速

```sql
openstack flavor set $i \

-property quota:vif_outbound_average=1500000 \
-property quota:vif_inbound_average=1500000 \
-property quota:vif_outbound_burst=2000000 \
-property quota:vif_inbound_burst=2000000

```

## 参数说明

```text
对实例的限制。有效选项包括：
cpu_period - 强制 cpu_quota 限制的时间（以 ms 为单位）。在指定的 cpu_period 时间中，每个 vCPU 不能占用超过 cpu_quota 的运行时。这个值的范围必须是 [1000, 1000000]，'0' 代表没有值。
cpu_quota - 在每个 cpu_period 时间段中 vCPU 所允许的最大带宽（以 ms 为单位）。这个值的范围必须是 [1000, 18446744073709551]，'0' 代表没有值，负值代表 vCPU 不被控制。cpu_quota 和 cpu_period 可以被用来保证所有 vCPU 以相同的速度运行。
cpu_shares - 为域共享 CPU 的时间。这个值只有在对同一个域中的其它机器加权重的情况下才有意义。一个云主机类型的相关值为 '200' 的实例会获得比相关值为 '100' 的实例多一倍的机器时间。
disk_read_bytes_sec - 每秒磁盘可以读取的最大数据量（以字节为单位）。
disk_read_iops_sec - 每秒所允许的最大读 I/O 操作。
disk_write_bytes_sec - 每秒磁盘可写的最大数据量（以字节为单位）。
disk_write_iops_sec - 每秒所允许的最大写 I/O 操作。
disk_total_bytes_sec - 每秒所允许的最大吞吐量总和的限制。
disk_total_iops_sec - 每秒所允许的最大总 I/O 操作。
vif_inbound_average - 期望的平均流入网络流量。
vif_inbound_burst - 在 vif_inbound_peak 速度上可以接收的最大网络流量。
vif_inbound_peak - 可以接收流入网络数据的最大速率。
vif_outbound_average - 期望的平均流出网络流量。
vif_outbound_burst - 在 vif_outbound_peak 速度上可以发送的最大网络流量。
vif_outbound_peak - 可以发送流出网络数据的最大速率。
例如：'quota:vif_inbound_average=10240'。

```

## 指定类型、物理机创建磁盘

```sql
openstack volume create --type g_sas --size 1 --availability-zone szbwx-az-int:szbwx-cloud-opsnode-T07-06-0816.example.com@sas test

```

## 删除没用的服务

```bash
cinder-manage service remove cinder-volume wxcy-cloud-controller01.example.com

```

## openstack调整虚拟机规格和热迁移自动确认

```ini
resize_confirm_window = 0

自动确认时间
0是禁用
1代表1s后自动确认

```
