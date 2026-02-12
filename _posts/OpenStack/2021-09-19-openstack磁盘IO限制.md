---
title: openstack磁盘IO限制
date: 2021-09-19 10:02:00
tags: ["存储", "Ceph", "云计算", "OpenStack"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2021-09-19-openstack磁盘IO限制/
---

本文档介绍 openstack磁盘IO限制 的相关内容。

```bash
限速级别：
80MB : 5000IOPS = 8 : 500 = 10:575峰值及比例

普通IO：每秒读写限制为50MB，iops限制为1000    50MB=52428800
高IO：每秒读写限制为120MB，iops限制为4000    120M=125829120
超高IO每秒读写限制为300MB, iops限制为15000   300M=314572800

```

> http://www.zhongguosou.com/computer_question_tools/data_rate_caculator.html   计算器

KVM磁盘限速

```bash
virsh blkdeviotune centos7.3_101_177_lvbeqpn vda --write-bytes-sec 100000000 --config --live
virsh blkdeviotune instance-00000005 vda --read-iops-sec 2000 --write-iops-sec 2000 --config --live
virsh blkdeviotune instance-00000005 vda --read-iops-sec 2000 --write-iops-sec 2000 --read-bytes-sec 20971520 --write-bytes-sec 20971520 --config --live

# 读写iops=2000 读写带宽=20M

virsh blkdeviotune --help

-config 写入配置文件 --live 立即生效

```

> https://www.cnblogs.com/nulige/p/9042660.html   动态加载虚拟机usb设备

Cinder 限制挂载卷：

```text
total_bytes_sec： 顺序读写总带宽上限
read_bytes_sec： 顺序读带宽上限
write_bytes_sec： 顺序写带宽上限
total_iops_sec： 随机读写总IOPS上限
read_iops_sec： 随机读IOPS上限
write_iops_sec： 随机写IOPS上限

```

```yaml
+ --------------------------------------+-----------+-----------+
| ID                                   | Name      | Is Public |

+ --------------------------------------+-----------+-----------+
| 5dfb9bfb-8cbb-4d37-adef-9730c6060eb5 | ceph-s-io | True      |
| 1122c650-2e0c-4f71-9668-3a3dc70e41ae | ceph-h-io | True      |
| e7531c39-9a39-4c35-b3e1-45fce450a85d | ceph-l-io | True      |

+ --------------------------------------+-----------+-----------+

# 创建一个 volume type，名为 cep-ssd

cinder type-create ceph-ssd --is-public true
openstack volume type create ceph-h-io --property volume_backend_name='RBD'

# 需要与配置文件cinder.conf中保持一致，才能进行关联：volume_backend_name = RBD

openstack volume type set  --property volume_backend_name='RBD' 8430beca-6fa8-4d78-b66d-94abe9a95b0a

+ ---------------------------------+--------------------------------------+
| Field                           | Value                                |

+ ---------------------------------+--------------------------------------+
| access_project_ids              | None                                 |
| description                     | ceph 高io                            |
| id                              | 8430beca-6fa8-4d78-b66d-94abe9a95b0a |
| is_public                       | True                                 |
| name                            | ceph-h-io                            |
| os-volume-type-access:is_public | True                                 |
| properties                      | volume_backend_name='RBD'            |
| qos_specs_id                    | 5663e97b-2cda-431f-9180-6de2fd30137b |

+ ---------------------------------+--------------------------------------+

```

```bash
# 创建 QoS spec

cinder qos-create ceph-ssd-qos consumer=front-end read_bytes_sec=10000000 write_bytes_sec=10000000 read_iops_sec=100 write_iops_sec=100
cinder qos-create ceph-qos consumer=front-end read_iops_sec=800 write_iops_sec=800

openstack volume qos create ceph-l-io \

-consumer front-end \
-property read_bytes_sec=52428800 \
-property write_bytes_sec=52428800 \
-property read_iops_sec=1000 \
-property write_iops_sec=1000

```

```bash
# 关联 QoS spec 和 volume type

cinder qos-associate fe3fbed7-faf3-4469-aef2-26f50af93a3f a7635028-3188-4c49-99c3-3620eae97ecb
cinder qos-associate <qos_specs> <volume_type_id>

openstack volume qos associate <qos_specs> <volume_type_id>

```

```sql
openstack flavor set FLAVOR-NAME \

-property quota:read_bytes_sec=52428800 \
-property quota:write_bytes_sec=52428800 \
-property quota:read_iops_sec=1000 \
-property quota:write_iops_sec=1000

 50MB=52428800   iops=1000
 120M=125829120  iops=4000
 300M=314572800  iops=15000

```

Flavor 限制虚拟机：
  https://blog.csdn.net/isclouder/article/details/79189022
http://kevinpig.github.io/2015/09/30/old/openstack-qos/
https://docs.openstack.org/nova/pike/admin/flavors.html
阿里云
https://help.aliyun.com/document_detail/25382.html?spm=5176.11065259.1996646101.searchclickresult.7ffa6931uU7EDD

```bash
# 设置iops 为800-1000 普通io  读写带宽普通为10M=10485760   高IO为20M=20971520

# 在线计算器 http://www.bejson.com/convert/filesize/

flavor set 8u16g80GB  --property quota:disk_write_iops_sec=800

The disk I/O options are:
disk_read_bytes_sec
disk_read_iops_sec
disk_write_bytes_sec
disk_write_iops_sec
disk_total_bytes_sec
disk_total_iops_sec

The vif I/O options are:
vif_inbound_average
vif_inbound_burst
vif_inbound_peak
vif_outbound_average
vif_outbound_burst
vif_outbound_peak

```
