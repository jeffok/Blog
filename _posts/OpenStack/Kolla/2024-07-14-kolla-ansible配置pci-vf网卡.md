---
title: kolla-ansible配置pci-vf网卡
date: 2024-07-14 13:41:00
tags: ["Kolla", "OpenStack", "Nova"]
categories: ["OpenStack", "Kolla"]
render_with_liquid: false
permalink: /posts/2024-07-14-kolla-ansible配置pci-vf网卡/
---

本文档介绍 kolla-ansible配置pci-vf网卡 的相关内容。

```ini
# cat nova-api.conf

[pci]
alias = {"name":"netvf", "product_id":"1520", "vendor_id":"8086", "device_type":"type-VF"}

# cat nova-scheduler.conf

[scheduler]
driver = filter_scheduler

[filter_scheduler]
available_filters = nova.scheduler.filters.all_filters
enabled_filters = AvailabilityZoneFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter,NUMATopologyFilter,AggregateInstanceExtraSpecsFilter,PciPassthroughFilter
weight_classes = nova.scheduler.weights.all_weighers
host_subset_size = 30
max_instances_per_host = 50

[pci]
alias = {"name":"netvf", "product_id":"1520", "vendor_id":"8086", "device_type":"type-VF"}

# cat nova-compute.conf

[DEFAULT]
sync_power_state_interval = -1

[libvirt]
virt_type = kvm
cpu_mode = host-passthrough
block_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_LIVE,VIR_MIGRATE_TUNNELLED,VIR_MIGRATE_NON_SHARED_INC
live_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED
images_type = lvm
images_volume_group = lvm-sas
volume_clear_size = 5

[pci]
passthrough_whitelist = { "vendor_id": "8086", "product_id": "1520" }
alias = {"name":"netvf", "product_id":"1520", "vendor_id":"8086", "device_type":"type-VF"}

```
