---
title: nova-manage cell_update
date: 2021-09-02 17:45:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2021-09-02-nova-manage-cell_update/
---

本文档介绍 nova-manage cell_update 的相关内容。

```sql
172. 19.136.73:5672,openstack:z0m3Qic56N@172.19.136.112:5672 va-manage  cell_v2 update_cell --cell_uuid c1dc012a-e004-4764-9e0a-e0bd66d4e6e5 --transport-url rabbit://openstack:z0m3Qic56N@172.19.136.94:5672,openstack:z0m3Qic56N@172.1

nova-manage  cell_v2 update_cell --cell_uuid c1dc012a-e004-4764-9e0a-e0bd66d4e6e5 --transport-url \
rabbit://openstack:z0m3Qic56N@172.19.136.94:5672,openstack:z0m3Qic56N@172.19.136.73:5672,openstack:z0m3Qic56N@172.19.136.112:5672

nova-manage  cell_v2  list_cells

nova-manage  cell_v2 update_cell --cell_uuid c1dc012a-e004-4764-9e0a-e0bd66d4e6e5

nova-manage cell_v2 update_cell --cell_uuid c1dc012a-e004-4764-9e0a-e0bd66d4e6e5 --database_connection mysql+pymysql://nova:uYGZHQTaV6BrLCUePZa5Z4xF80hpqA7FMevSunGs@172.19.136.10:3306/nova

mysql+pymysql://nova:****@172.19.136.10:3306/nova
mysql+pymysql://nova:****@172.19.136.10:3306/nova_cell0\

stack@controller:/opt/stack/devstack$ nova-manage cell_v2 update_cell --cell_uuid 220faf2d-fab8-4c47-bf02-4270f1e380be --database_connection mysql+pymysql://root:root@192.168.100.30/nova_cell1?charset=utf8

stack@controller:/opt/stack/devstack$ nova-manage cell_v2 update_cell --cell_uuid 00000000-0000-0000-0000-000000000000 --database_connection mysql+pymysql://root:root@192.168.100.30/nova_cell0?charset=utf8

```
