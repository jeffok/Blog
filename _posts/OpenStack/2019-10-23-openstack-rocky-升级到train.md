---
title: openstack rocky  升级到train
date: 2019-10-23 09:25:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/posts/2019-10-23-openstack-rocky-升级到train/
---

## 描述

通过kolla-ansible openstack环境进行升级，跨版本升级后如存在cpupin的虚拟机，会导致不能正常分配。

## 修改`nova`数据库中`instance_extra`表中字段为`numa_topology` <br>

## 修改内容

```text
cpu_pinning_raw cpu对应关系
id 与cpu的对应关系，当前我们设置为1号cpu做为绑定，0做为共享

```

## 修改`nvoa`数据库中`compute_nodes`表中字段为`numa_topology` <br>

```ini
修改nova_object.data 中cells 中，id=0 为非绑定cpu数据
nova_object  增加"pcpuset", 值
cpu_usage 实际使用情况
memory_usage 实际使用情况
pinned_cpus 为空

修改nova_object.data 中cells 中，id=1 为绑定cpu数据
nova_object  增加"pcpuset", 值
cpu_usage 实际使用情况
memory_usage 实际使用情况
pinned_cpus 与cpu_pinning_raw 对应，且在pcpuset中存在

```
