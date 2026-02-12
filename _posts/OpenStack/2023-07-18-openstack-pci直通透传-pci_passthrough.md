---
title: openstack pci直通透传(pci_passthrough)
date: 2023-07-18 17:09:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2023-07-18-openstack-pci直通透传-pci_passthrough-/
---
> https://blog.csdn.net/zxycyj1989/article/details/103995482

> https://docs.openstack.org/neutron/latest/admin/config-sriov.html#configure-nova-scheduler-controller

> https://docs.openstack.org/nova/pike/admin/pci-passthrough.html

## 开启iommu

使用如下命令确认是否支持iommu

```bash
cat /proc/cmdline | grep iommu

```

如果没有输出，说明不支持iommu，需要手动开启。编辑/etc/default/grub，在GRUB_CMDLINE_LINUX中添加intel_iommu=on配置项：

```ini
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="intel_iommu=on crashkernel=auto rhgb quiet"
GRUB_DISABLE_RECOVERY="true"

```

更新grub，并重启设备

```text
grub2-mkconfig -o /boot/grub2/grub.cfg
shutdown -r now

```

重启以后如下确认是否正常：

```bash
# 使用下面命令

dmesg | grep -i iommu

# 如果输出类似下面的内容，说明正确

[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-3.10.0-862.6.3.el7.x86_64 root=UUID=4e83b2b5-5ff1-4b1b-af0f-3f6a7f8275ea ro intel_iommu=on crashkernel=auto rhgb quiet
[    0.000000] Kernel command line: BOOT_IMAGE=/boot/vmlinuz-3.10.0-862.6.3.el7.x86_64 root=UUID=4e83b2b5-5ff1-4b1b-af0f-3f6a7f8275ea ro intel_iommu=on crashkernel=auto rhgb quiet
[    0.000000] DMAR: IOMMU enabled
[    0.257808] DMAR-IR: IOAPIC id 3 under DRHD base  0xfbffc000 IOMMU 0
[    0.257810] DMAR-IR: IOAPIC id 1 under DRHD base  0xd7ffc000 IOMMU 1
[    0.257812] DMAR-IR: IOAPIC id 2 under DRHD base  0xd7ffc000 IOMMU 1

```

## 虚拟化支持确认

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo

# 如果输入非0，则说明支持

```

## 配置vfio

```bash
lspci -nn | grep NVID
lspci -nn | grep mem

# 可以看到，其实我的这台设备上有两个个vga设备（就是我们服务器上的2080），这两个pci设备一共有4个硬件：VGA、Audio、USB、Serial bus

```

## openstack配置

控制节点配置  nova-api nova-scheduler

```ini
[filter_scheduler]
available_filters = nova.scheduler.filters.all_filters

# 主要在末尾添加：PciPassthroughFilter

enabled_filters = RetryFilter,AvailabilityZoneFilter,ComputeFilter,ComputeCapabilitiesFilter,RamFilter,CoreFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter,PciPassthroughFilter
[pci]

# alias是能够直通设备的信息，多个设备多条记录，我们希望GPU上的4个设备都直通到虚拟机，所以将4个设备信息都写上

alias = {"name":"nv2080vga","product_id":"1e04","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080aud","product_id":"10f7","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080usb","product_id":"1ad6","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080bus","product_id":"1ad7","vendor_id":"10de","device_type":"type-PCI"}

```

配置完成以后，重启nova 相关服务（nova-api和nova-scheduler：

```bash
systemctl restart openstack-nova-api.service openstack-nova-scheduler.service

```

配置计算节点

```ini
[pci]

# alias可以配置多条，对应多个设备

alias = {"name":"nv2080vga","product_id":"1e04","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080aud","product_id":"10f7","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080usb","product_id":"1ad6","vendor_id":"10de","device_type":"type-PCI"}
alias = {"name":"nv2080bus","product_id":"1ad7","vendor_id":"10de","device_type":"type-PCI"}

# passthrough_whitelist配置该计算节点可用于直通的设备

passthrough_whitelist = [{ "vendor_id": "10de", "product_id": "1e04" },
			             { "vendor_id": "10de", "product_id": "10f7" },
                         { "vendor_id": "10de", "product_id": "1ad6" },
                         { "vendor_id": "10de", "product_id": "1ad7" }]

```

重启计算服务：

```bash
systemctl restart openstack-nova-compute

```

创建带有显卡直通信息的flavor

```sql
openstack flavor create --public --ram 2048 --disk 20 --vcpus 2 m1.large

openstack flavor set m1.large --property pci_passthrough:alias='nv2080vga:2,nv2080aud:2,nv2080usb:2,nv2080bus:2'

```

## 隐藏虚拟机的hypervisor id

因为NIVIDIA显卡的驱动会检测是否跑在虚拟机里，如果在虚拟机里驱动就会出错，所以我们需要对显卡驱动隐藏hypervisor id。在OpenStack的Pile版本中的Glance 镜像引入了img_hide_hypervisor_id=true的property，所以可以对镜像执行如下的命令隐藏hupervisor id：

```sql
openstack image set [IMG-UUID] --property img_hide_hypervisor_id=true

# 通过此镜像安装的instance就会隐藏hypervisor id。

```

可以通过下边的命令查看hypervisor id是否隐藏：

```ini
cpuid | grep hypervisor_id
hypervisor_id = "KVMKVMKVM   "
hypervisor_id = "KVMKVMKVM   "

```

上边的显示结果说明没有隐藏，下边的显示结果说明已经隐藏：

```ini
cpuid | grep hypervisor_id
hypervisor_id = "  @  @    "
hypervisor_id = "  @  @    "

```
