---
title: PCI透传PCI passthrough
date: 2024-09-01 08:00:00
tags: ["内核", "网络", "Linux", "虚拟化", "KVM"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2024-09-01-PCI透传PCI-passthrough/
---

#### 参考文档

> https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87) PCI passthrough via OVMF (简体中文) <br>
> http://www.99cloud.net/10694.html%EF%BC%8F   OpenStack vf配置 <br>
> https://www.backendcloud.cn/2018/10/14/sriov/  vf配置<br>
> https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux_openstack_platform/7/html/networking_guide/sec-sr-iov  sriov_vf 配置<br>

```bash
# 回绑：

echo  "8086 0a54" > /sys/bus/pci/drivers/nvme/new_id
echo  0000:d8:00.0 > /sys/bus/pci/drivers/pci-stub/unbind
echo  0000:d8:00.0 > /sys/bus/pci/drivers/nvme/bind

# 解绑：

modprobe pci_stub
echo 0000:d8:00.0 > /sys/bus/pci/devices/0000\:d8\:00.0/driver/unbind
echo "8086 0a54" > /sys/bus/pci/drivers/pci-stub/new_id

```

查看intel nvme磁盘信息

```sql
isdct show -a -intelssd 1

```

linux查看pci设备命令

> 选项与参数 </br>
> -v : 显示更多的pci接口设备的详细信息</br>
> -vv: 比-v还要详细的信息</br>
> -n : 直接观察pci的id而不是厂商名称</br>

查看一般详细信息

```text
lspci -v

```

查看网卡详细信息

```bash
lspci -s 04:00.0 -vv

# -s 后面接的是每个设备的总线、插槽与相关函数功能

或：
lspci -n -d 8080:3002 -vvv

```

查看nvme磁盘对应的NUMA

```bash
lspci -s d8:00.0 -vv|grep NUMA

```

### 配置物理机及内核参数

> 确认宿主机的硬件支持，主要是cpu和主板，这可以查看官方的硬件支持列表，或者在BIOS中查看相关选项。以Intel硬件为例，主要就是：
> > VT-x：处理器技术，提供内存以及虚拟机的硬件隔离，所涉及的技术有页表管理以及地址空间的保护。
> > VT-d：处理有关芯片组的技术，它提供一些针对虚拟机的特殊应用，如支持某些特定的虚拟机应用跨过处理器I/O管理程序，直接调用I/O资源，从而提高效率，通过直接连接I/O带来近乎完美的I/O性能。
> > VT-c：针对网络提供的管理，它可以在一个物理网卡上，建立针对虚拟机的设备队列。
> > 物理机BIOS中开启SR-IOV，如果未开启，不支持VF或PF的功能，同时需要开启vt-x或vt-d相关的参数，一般情况在BIOS中advanced下CPU和system或相关的设置条目中，都设置为Enabled
> ```

> VT：Intel Virtualization Technology
> VT-d：Intel VT for Directed I/O
> VT-c：I/O Virtualization
> ```

##### 修改内核启动参数，使IOMMU生效

```bash
# cat /etc/default/grub

…
GRUB_CMDLINE_LINUX="rhgb quiet kvm-intel.nested=1 intel_iommu=on"

# 在GRUB_CMDLINE_LINUX后加上intel_iommu=on，其他的不动

intel_iommu=pt

```

##### 重新生成内核参数

```text
grub2-mkconfig -o /boot/grub2/grub.cfg

```

##### 重启机器后执行如下两条命令进行确认

```bash
# find /sys/kernel/iommu_groups/ -type l

# dmesg | grep -e DMAR -e IOMMU

# 如果有输出，那就说明ok了。如果没有，那再验证BIOS、内核编译项、内核启动参数等是否没有正确配置。比如内核是否已经编译了IOMMO：

# cat /boot/config-3.10.0-862.el7.x86_64 |grep IOMMU

CONFIG_GART_IOMMU=y

# CONFIG_CALGARY_IOMMU is not set

CONFIG_IOMMU_HELPER=y
CONFIG_VFIO_IOMMU_TYPE1=m
CONFIG_VFIO_NOIOMMU=y
CONFIG_IOMMU_API=y
CONFIG_IOMMU_SUPPORT=y
CONFIG_IOMMU_IOVA=y
CONFIG_AMD_IOMMU=y
CONFIG_AMD_IOMMU_V2=m
CONFIG_INTEL_IOMMU=y

```

### 配置pci设备使用pci_stub

> pci_stub主要用于pci磁盘等单个vf的设备

##### 通过ethtool查看网卡的bus信息

```bash
# ethtool -i enp8s0f0 | grep bus

bus-info: 0000:08:00.0

```

##### 解除绑定（注意里面的0000:08:00.0是上一步获得的bus信息）

```bash
# lspci -s 0000:08:00.0 -n

08:00.0 0200: 8086:10c9 (rev 01)

# modprobe pci_stub

# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind

# echo “8086 10c9″ > /sys/bus/pci/drivers/pci-stub/new_id

```

##### 驱动确认（注意里面的：Kernel driver in use: pci-stub）

```bash
# lspci -s 0000:08:00.0 -k

08:00.0 Ethernet controller: Intel Corporation 82576 Gigabit Network Connection (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: pci-stub
Kernel modules: igb

```

##### 启动虚拟机

```text
kvm -name centos7 -smp 4 -m 8192 \

drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
nographic -vnc :2 \
net none -device pci-assign,host=0000:08:00.0

```

### 配置vfio

##### 加载vfio模块

```bash
# modprobe vfio

# modprobe vfio-pci

```

##### 解绑及绑定vfio

```bash
# echo “8086 10c9″ > /sys/bus/pci/drivers/vfio-pci/new_id

# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind

# 绑定

# echo 0000:08:00.0 > /sys/bus/pci/drivers/vfio-pci/bind

```

##### 启动虚拟机

```text
kvm -name centos7 -smp 4 -m 8192 \

drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
nographic -vnc :2 \
net none -device vfio-pci,host=0000:08:00.0

```

##### 查看设置使用的驱动类型

```text
lspci -s 0000:08:00.0 -k

```

### 配置网卡vf

##### 检查设备是否支持SR-IOV

```bash
# lspci -s 0000:08:00.0 -vvv | grep -i “Single Root I/O Virtualization”

Capabilities: [160 v1] Single Root I/O Virtualization (SR-IOV)

```

##### 重新绑定到igb驱动

```bash
# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind

# echo “8086 10c9″ > /sys/bus/pci/drivers/igb/new_id

bash: echo: write error: File exists

# echo “8086 10c9″ > /sys/bus/pci/drivers/igb/bind

bash: echo: write error: No such device

# 出现上面这些错误，当前还不知道怎么回事，可能是因为我关闭kvm都是直接在宿主机里kill掉进程的，导致bus信息未释放？待进一步分析。

# echo igb > /sys/bus/pci/devices/0000\:08\:00.0/driver_override

# echo 0000:08:00.0 > /sys/bus/pci/drivers_probe

# lspci -s 0000:08:00.0 -k

08:00.0 Ethernet controller: Intel Corporation 82576 Gigabit Network Connection (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: igb
Kernel modules: igb

```

##### 创建VF，可以通过重新加载内核模块参数来创建VF(不推荐)

```bash
# modprobe -r igb; modprobe igb max_vfs=7

# 如果远程网卡也是用的igb，则会导致断网。因此还是直接只对0000:08:00.0网卡开启VF：

# lspci -nn | grep “Virtual Function”

# echo 2 > /sys/bus/pci/devices/0000\:08\:00.0/sriov_numvfs

# lspci -nn | grep “Virtual Function”

08:10.0 Ethernet controller [0200]: Intel Corporation 82576 Virtual Function [8086:10ca] (rev 01)
08:10.2 Ethernet controller [0200]: Intel Corporation 82576 Virtual Function [8086:10ca] (rev 01)

# echo 0 > /sys/bus/pci/devices/0000\:08\:00.0/sriov_numvfs

# lspci -nn | grep “Virtual Function”

# 也就是对sriov_numvfs进行数字写入，表示创建几个VF，写入0则删除所有VF。

# 如果要重启生效，那还是在模块加载时指定参数：

# echo “options igb max_vfs=2″ >>/etc/modprobe.d/igb.conf

```

##### 查看网络的PCI相关信息

```json
[root@sze0-devops-jeff ~]# lshw -c network -businfo
Bus info          Device      Class          Description
========================================================
pci@0000:02:00.0  enp2s0f0    network        I350 Gigabit Network Connection
pci@0000:02:00.1  enp2s0f1    network        I350 Gigabit Network Connection
pci@0000:81:00.0  enp129s0f0  network        Ethernet Controller X710 for 10GbE SFP+
pci@0000:81:00.1  enp129s0f1  network        Ethernet Controller X710 for 10GbE SFP+
pci@0000:81:0a.0              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.1              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.2              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.3              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.4              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.5              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.6              network        Ethernet Virtual Function 700 Series
pci@0000:81:0a.7              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.0              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.1              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.2              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.3              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.4              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.5              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.6              network        Ethernet Virtual Function 700 Series
pci@0000:81:0b.7              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.0              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.1              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.2              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.3              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.4              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.5              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.6              network        Ethernet Virtual Function 700 Series
pci@0000:81:0c.7              network        Ethernet Virtual Function 700 Series

```

##### 配置vf网卡为vfio-pci并启动虚拟机

```bash
# ethtool -i enp8s16 | grep bus

bus-info: 0000:08:10.0

# lspci -s 0000:08:10.0 -n

08:10.0 0200: 8086:10ca (rev 01)

# modprobe vfio

# modprobe vfio-pci

# echo 0000:08:10.0 > /sys/bus/pci/devices/0000\:08\:10.0/driver/unbind

# echo “8086 10ca” > /sys/bus/pci/drivers/vfio-pci/new_id

# 绑定

# echo 0000:08:10.0 > /sys/bus/pci/drivers/vfio-pci/bind

# lspci -s 0000:08:10.0 -k

08:10.0 Ethernet controller: Intel Corporation 82576 Virtual Function (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: vfio-pci
Kernel modules: igbvf

# kvm -name centos7 -smp 4 -m 8192 \

drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
nographic -vnc :2 \
net none -device vfio-pci,host=0000:08:10.0

```

> 由于网卡在使用中大部分都是双接口，但是为了只使用其中一个接口，那么我们需要手动来配置这些信息。不能将绑定信息配置在内核模板上

##### 绑定vfio设备

```bash
echo "options vfio-pci ids=10de:1c81,10de:0fb9" > /etc/modprobe.d/vfio.conf

```

##### 开机加载vfio模块

```bash
echo 'vfio-pci' > /etc/modules-load.d/vfio-pci.conf

# 验证

dmesg | grep -i vfio

```

##### 开启某一块网卡的vf

```bash
# cat /etc/rc.local

echo 24 > /sys/bus/pci/devices/0000\:81\:00.1/sriov_numvfs

```

##### 查看网卡支持的vf数量

```bash
cat /sys/bus/pci/devices/0000:41:00.0/sriov_totalvfs

```

##### 宿主屏蔽VF驱动后查看vf和pf的对应

```text
载下来后执行./listvfs_by_pf.sh即可

```

##### 宿主屏蔽VF后查看哪些VF正在被使用

```bash
yum install dpdk-tools
dpdk-devbind --status

```

##### 查看网卡对应哪个socket

```bash
yum install hwloc
lstopo-no-graphics
/usr/bin/hwloc-info

```

##### lspci查看网卡信息

```bash
lspci -Dvmm|grep -B 1 -A 4 Ethernet

```

##### 宿主上查看具体VF流量（仅支持x520，x710查不到）

```bash
ethtool -S p1p1 | grep VF

```
