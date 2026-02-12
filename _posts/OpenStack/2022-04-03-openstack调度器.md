---
title: openstack调度器
date: 2022-04-03 08:48:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2022-04-03-openstack调度器/
---
openstack Train版本默认设置开启的调度器：（跟rocky之前的版本有一定的区别）

[scheduler]
driver = filter_scheduler

[filter_scheduler]
available_filters = nova.scheduler.filters.all_filters
enabled_filters = AvailabilityZoneFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter

openstack nova 使用nova-scheduler服务来确定如何调度计算请求，确定VM应该在哪个主机上启动。当前openstack train版本目前已支持多种调度器配置，下面展开介绍一下：

AvailabilityZoneFilter
按可用性区域过滤主机，必须启用此筛选器，以使调度程序尊重请求中的可用域；

ComputeFilter
过滤所有nova compute服务运行正常的主机，必须启动；

ImagePropertiesFilter
根据镜像元数据进行过滤，
例如，设置image --property hypervisor_type=kvm，hypervisor_version_requires=">=4.3"，创建的虚拟机会调度到相应的匹配的宿主机上去；

AggregateImagePropertiesIsolation
将image元数据中定义的属性与可用域中的属性进行匹配，以确定虚拟机分配：
例如：可用域设置named "windows"的metadata，image 设置 os_distro='windows'，则使用这个镜像创建的虚拟机就是调度到可用域中的主机上。

SimpleCIDRAffinityFilter

## 创建实例调度到同一个子网

## 例如

openstack server create --image cedef40a-ed67-4d10-800e-17455edce175 \

- -flavor 1 --hint build_near_host_ip=192.168.1.1 --hint cidr=/24 server-1

AggregateInstanceExtraSpecsFilter
根据额外的主机属性进行过滤（Host Aggregate元数据），使用flavor中定义的元数据域与可用域中的属性进行匹配，以确定虚拟机分配：

## 例如

nova aggregate-set-metadata szgl-test io=fast
nova flavor-key g_2u2g40G set io=fast
以flavor g_2u2g40G 创建的虚拟机会调度到可用域szgl-test中的主机上；

AggregateIoOpsFilter
根据主机的IO负载过滤，根据配置max_io_ops_per_host（默认是8），超过8个io密集型虚拟机的宿主机会过滤掉，不会被调度。

AggregateMultiTenancyIsolation
把租户隔离在指定的Aggregate，多租户的环境，不会使用

AggregateNumInstancesFilter
根据节点实例个数来过滤，过滤具有总计max_instances_per_host值的主机，宿主机上超过这个虚拟机数量不会被调度到；max_instances_per_host = 13

下面这几个过滤器rocky版本后就弃用了，nova里面配置ram_allocation_ratio = 1.0 disk_allocation_ratio = 1.0 cpu_allocation_ratio = 2.0
等去过滤，或者直接使用placement api。
AggregateCoreFilter
AggregateRamFilter
RamFilter
CoreFilter cpu核心
DiskFilter 磁盘
RetryFilter 重新尝试

SameHostFilter
把虚拟机调度到同个宿主机上，要利用此过滤器，请求者必须传递调度程序提示，并使用same_host作为键，并将实例UUID的列表用作值。

## 测试环境测试

nova --debug boot hujhtest01 --flavor g_1u2g10GB --nic net-id=1fdaebea-56bf-4652-b2e6-090db3134090 --availability-zone szgl-az-dev1 --block-device id=0c93ff77-d760-4ee6-a7b3-ac41db8a403c,source=image,dest=volume,device=vda,size=10,bootindex=0,shutdown=remove,volume_type=g_sas

nova --debug boot hujhtest02 --flavor g_1u2g10GB --nic net-id=1fdaebea-56bf-4652-b2e6-090db3134090 --hint same_host=4c9fb324-d268-4f64-b3e4-ba85c5024e10 --block-device id=0c93ff77-d760-4ee6-a7b3-ac41db8a403c,source=image,dest=volume,device=vda,size=10,bootindex=0,shutdown=remove,volume_type=g_sas

DifferentHostFilter
将虚拟机调度到不同的宿主机上去，要利用此过滤器，请求者必须传递调度程序提示，并使用 different_host作为键，并将实例UUID的列表用作值。
nova --debug boot hujhtest03 --flavor g_1u2g10GB --nic net-id=1fdaebea-56bf-4652-b2e6-090db3134090 --hint different_host=4c9fb324-d268-4f64-b3e4-ba85c5024e10 --block-device id=0c93ff77-d760-4ee6-a7b3-ac41db8a403c,source=image,dest=volume,device=vda,size=10,bootindex=0,shutdown=remove,volume_type=g_sas

结果符合预期。

ServerGroupAffinityFilter
亲和性调度，虚拟机要求调度创建在同个计算节点上，通过openstack的server group实现；

ServerGroupAntiAffinityFilter
反亲和性调度，虚拟机要求不能调度创建在同个节点上，通过openstack的server group实现；

## 例如

假设业务要求app的虚拟机要创建在同个物理机上，database的虚拟机不能创建在同个物理机上；

具体实现：创建两个server group app 和 database
openstack server group create --policy affinity app
openstack server group create --policy anti-affinity database
openstack server group list --long | grep -Ei "Policies|app|database"
那么，在创建虚拟机的时候指定server group就能实现app的虚拟机都会调度在同个物理机上，database的虚拟机会创建到不同的物理机上去。
–hint group=<Server-Group-ID>
openstack server create --image Cirros --flavor m1.small --security-group default --nic net-id=37b9ab9a-f198-4db1-a5d6-5789b05bfb4c --hint group="a9847c7f-b7c2-4751-9c9a-03b117e704ff" --max 4 affinity-test
openstack server create --image Cirros --flavor m1.small --security-group default --nic net-id=37b9ab9a-f198-4db1-a5d6-5789b05bfb4c --hint group="498fd41b-8a8a-497a-afd8-bc361da2d74e" --max 4 anti-affinity-test

PciPassthroughFilter
根据请求的PCI设备进行过滤，将虚拟机调度到有pci extra_specs属性设置的宿主机上去，nvme ssd透传即使用了此过滤器。

NUMATopologyFilter
根据实例的NUMA要求过滤主机，flavor中配置cpu绑定策略即使用了此过滤器，当然还有相关numa node 的设置等。

例如；
nova flavor-key c_2u2g10GB set hw:cpu_policy=dedicated hw:cpu_thread_policy=require

IsolatedHostsFilter
根据nova.conf中的image_isolated、 host_isolated，和restrict_isolated_hosts_to_isolated_images 标志进行过滤，用于节点隔离，隔离的映像只能在隔离的主机上运行，​​而隔离的主机只能运行隔离的映像。
需要nova里面restrict_isolated_hosts_to_isolated_images要设置为True（默认就是）才会生效：
[filter_scheduler]
isolated_hosts = server1, server2
isolated_images = 342b492c-128f-4a42-8d3a-c5088cf27d13, ebd267a6-ca86-4d6c-9a0e-bd132d6b7d09

当前在开发测试环境中展开测试，还有权重这一块相关的配置测试，陆续会整理到此文档中。