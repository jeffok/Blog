---
title: OpenStack虚拟机资源限制
date: 2019-08-23 08:24:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2019-08-23-OpenStack虚拟机资源限制/
---

## 目标

* 通过nova服务的flavor模板中的元数据，来限制虚拟机CPU、磁盘IO资源等，以保证物理机以正常速度运行,也可以使不同的虚拟机以同样的速度运行。*

## 准备

- openstack
- nova
- vm

## 过程

## 创建vm模板

* test模板 id为10 内存4G 硬盘100G vcpu4个*

```sql
[root@controller ~]# nova flavor-create test 10 4096 100 4

```

限制磁盘速度：

* 读写速度均为10MB*

```json
[root@controller ~]# nova flavor-key test set quota:disk_read_bytes_sec=10240000
[root@controller ~]# nova flavor-key test set quota:disk_write_bytes_sec=10240000

```

限制cpu占用比例（5%）：

```json
[root@controller ~]# nova flavor-key test set quota:cpu_period=1000000
[root@controller ~]# nova flavor-key test set quota:cpu_quota=50000

```

## 测试：

```json
[root@controller ~]# nova boot --image centos7.2 --flavor test --nic net-name=int-net1 test

```

## 磁盘读写测试：

* 设置不同的块大小，测试结果均为10MB。*

```json
[root@test ~]# dd if=/dev/zero of=testfile bs=8k count=5000 oflag=direct
5000+0 records in
5000+0 records out
40960000 bytes (41 MB) copied, 3.90028 s, 10.5 MB/s
[root@test ~]# dd if=/dev/zero of=testfile bs=1M count=50 oflag=direct
50+0 records in
50+0 records out
52428800 bytes (52 MB) copied, 4.9546 s, 10.6 MB/s
[root@test ~]# dd if=/dev/zero of=testfile bs=10M count=50 oflag=direct
50+0 records in
50+0 records out
524288000 bytes (524 MB) copied, 50.9428 s, 10.3 MB/s

```

## cpu测试：

* 虚拟机cpu限制为5%等于400%\*0.05=20%，也就是说虚拟机最多使用已分配资源的20%。*

创建cpu负载：

```json
[root@test ~]# stress -c 24
stress: info: [10215] dispatching hogs: 4 cpu, 0 io, 0 vm, 0 hdd

```

cpu负载情况：

```bash
[root@test ~]# top -s
Tasks: 122 total,  18 running, 104 sleeping,   0 stopped,   0 zombie
%Cpu0  :  5.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si, 95.0 st
%Cpu1  :  5.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si, 95.0 st
%Cpu2  :  5.3 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si, 94.7 st
%Cpu3  :  5.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si, 95.0 st
KiB Mem :  4047276 total,  3837488 free,    84040 used,   125748 buff/cache
KiB Swap:        0 total,        0 free,        0 used.  3801536 avail Mem

```

* 5+5+5.3+5=20%,可见cpu资源被限制。*
附：
云主机类型：

```yaml
[root@controller ~]# nova flavor-show test

+ ----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| Property                   | Value                                                                                                                                          |

+ ----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| OS-FLV-DISABLED:disabled   | False                                                                                                                                          |
| OS-FLV-EXT-DATA:ephemeral  | 0                                                                                                                                              |
| disk                       | 100                                                                                                                                            |
| extra_specs                | {"quota:disk_read_bytes_sec": "10240000", "quota:cpu_period": "1000000", "quota:disk_write_bytes_sec": "10240000", "quota:cpu_quota": "50000"} |
| id                         | 21e74ec4-d7a2-4902-917c-a4487cecc5cc                                                                                                           |
| name                       | test                                                                                                                                           |
| os-flavor-access:is_public | True                                                                                                                                           |
| ram                        | 4096                                                                                                                                           |
| rxtx_factor                | 1.0                                                                                                                                            |
| swap                       |                                                                                                                                                |
| vcpus                      | 4                                                                                                                                              |

+ ----------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+

```
