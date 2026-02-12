---
title: RabbitMQ 调整RAM内存模式
date: 2019-07-23 13:53:00
tags: ["云计算", "OpenStack"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2019-07-23-RabbitMQ-调整RAM内存模式/
---

## RabbitMQ 更改节点 内存模式/硬盘模式

为了提高性能，不需要所有节点都是disc的节点,所以启动一个节点为RAM模式。

* 提示: RAM节点仅将其元数据保留在内存中，如果群集停止，该节点的所有数据将会丢失。

### 更改节点模式(内存模式)

更改节点: rabbit@rabbit01为内存模式,操作如下：

```text
rabbitmqctl -n rabbit@rabbit01 stop_app
rabbitmqctl -n rabbit@rabbit01 change_cluster_node_type ram
rabbitmqctl -n rabbit@rabbit01 start_app

```

查看ram状态

```json
[root@rabbit01 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@rabbit01 ...
[{nodes,[{disc,['rabbit@rabbit02','rabbit@rabbit03']}, # disc 为硬盘模式
         {ram,['rabbit@rabbit01']}]},  # ram 为内存模式
 {running_nodes,['rabbit@rabbit02','rabbit03',
                 'rabbit@rabbit01']},
 {cluster_name,<<"rabbit@rabbitmq_cluster">>},
 {partitions,[]},
 {alarms,[{'rabbit@rabbit01',[]},
          {'rabbit@rabbit02',[]},
          {'rabbit@rabbit03',[]}]}]

```

### 更改节点模式(硬盘模式)

更改节点: rabbit@rabbit02为硬盘模式,操作如下：

```text
rabbitmqctl -n rabbit@rabbit02 stop_app
rabbitmqctl -n rabbit@rabbit02 change_cluster_node_type disc
rabbitmqctl -n rabbit@rabbit02 start_app

```
