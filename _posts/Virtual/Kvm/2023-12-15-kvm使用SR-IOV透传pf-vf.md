---
title: kvm使用SR-IOV透传pf-vf
date: 2023-12-15 11:39:00
tags: ["内核", "网络", "Linux", "RedHat"]
categories: ["Virtual", "Kvm"]
render_with_liquid: false
permalink: /posts/2023-12-15-kvm使用SR-IOV透传pf-vf/
---
> http://www.rendoumi.com/sr-iovyu-kvmyi-ji-open-vswitchde-pei-he/
> https://access.redhat.com/documentation/zh-cn/red_hat_virtualization/4.0/html/installation_guide/appe-configuring_a_hypervisor_host_for_pci_passthrough

什么是SR-IOV呢? <br>
简单的说，SR-IOV是一种虚拟化方案，用来使一个PCIe的物理设备，能虚拟出多个设备，这些虚拟出来的设备看起来就像是多个真实的物理设备一样，并获得能够与本机性能媲美的 I/O 性能。<br>

SR-IOV现在最多是用在网卡上，kvm虚拟机的网卡功能一般会下降到实体机的30-50%，如果改用SR-IOV会大大提高网卡性能。

## SR-IOV 有2种功能

- 物理功能 (Physical Function, PF)

### 就是标准的PCIe的功能了

- 虚拟功能 (Virtual Function, VF)

    - 与物理功能关联的一种功能。VF 是一种轻量级 PCIe 功能，可以与物理功能以及与同一物理功能关联的其他 VF 共享一个或多个物理资源。VF 仅允许拥有用于其自身行为的配置资源。

好的，如何在生产环境中使用它呢？

场景如下：<br>
<img src=http://note.youdao.com/yws/res/4189/0585315A55E64A4496E6A8BABB44D431 width=550>

修改内核以支持sr-iov

```ini
# vi /etc/default/grub

intel_iommu=on

```

查看pci设备

```bash
# lspci -Dnn|grep net

lspci
01:00.0 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
01:00.1 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
01:00.2 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
01:00.3 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)

```

```text
lspci -s 01:00.0 -vvvv
01:00.0 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
    Subsystem: Dell Gigabit 4P I350-t rNDC
    Flags: bus master, fast devsel, latency 0, IRQ 46
    Memory at 91e00000 (32-bit, non-prefetchable) [size=1M]
    Memory at 91f0c000 (32-bit, non-prefetchable) [size=16K]
    Expansion ROM at 91f80000 [disabled] [size=512K]
    Capabilities: [40] Power Management version 3
    Capabilities: [50] MSI: Enable- Count=1/1 Maskable+ 64bit+
    Capabilities: [70] MSI-X: Enable+ Count=10 Masked-
    Capabilities: [a0] Express Endpoint, MSI 00
    Capabilities: [e0] Vital Product Data
    Capabilities: [100] Advanced Error Reporting
    Capabilities: [140] Device Serial Number ec-f4-bb-ff-ff-d9-96-43
    Capabilities: [150] Alternative Routing-ID Interpretation (ARI)
    Capabilities: [160] Single Root I/O Virtualization (SR-IOV)
    Capabilities: [1a0] Transaction Processing Hints
    Capabilities: [1c0] Latency Tolerance Reporting
    Capabilities: [1d0] Access Control Services
    Kernel driver in use: igb
    Kernel modules: igb

```

> 注意上面有一行表示是支持的： Capabilities: [160] Single Root I/O Virtualization (SR-IOV)

然后我们必须激活VFs，上面我们lspci查看四个I350网卡的usb id，em1是01:00.0，em2是01:00.1，em3是01:00.2，em4是01:00.4，激活em1和em2的VFs

```bash
echo 7 >  /sys/bus/pci/devices/0000\:01\:00.0/sriov_numvfs
echo 7 >  /sys/bus/pci/devices/0000\:01\:00.0/sriov_numvfs

```

定义网络池，只要指定pf即可，vf会动态分配给虚拟机

```bash
cat net01.xml
<network>
  <name>passthrough_em1</name>
  <forward mode='hostdev' managed='yes'>
    <pf dev='em1'/>
  </forward>
</network>

cat net02.xml
<network>
  <name>passthrough_em2</name>
  <forward mode='hostdev' managed='yes'>
    <pf dev='em2'/>
  </forward>
</network>

```

启动这2个网络：

```bash
virsh net-define net01.xml
virsh net-start passthrough_em1
virsh net-autostart passthrough_em1

virsh net-define net02.xml
virsh net-start passthrough_em2
virsh net-autostart passthrough_em2

modprobe vfio

```

我们编辑虚机的xml配置文件

```bash
...
    <interface type="network">
      <source network="passthrough_em1"/>
    </interface>
    <interface type="network">
      <source network="passthrough_em2"/>
    </interface>
...

```

注意，em1和em2的bonding参数，在实体机和虚机中的bonding配置是一样的：

```ini
BONDING_OPTS="miimon=80 mode=1 primary=eth0 updelay=30000"

```

为避免频繁切换，updelay设置为30秒

例外： 实机和虚机的bonding是一样的，如果实机网卡eth0坏了，eth1接管，那么虚机中同样也会飘到eth1。这里有个问题，如果网卡处于bonding状态，那么所有的网卡的mac地址都是一样的，如果eth0挂了，那么bongding的驱动程序会去改变eth1的mac地址，把老的eth0的地址赋给eth1，在实体机上，mac都一样，所以会拒绝，但是在虚机上却会成功，这样就导致虚机和实机在同一个网卡上有两个不同的mac地址，发到虚机上eth1的包会被当成mac spoof而被丢掉。

解决方法是bonding参数加上failovermac=active 或者设置spoofchk off，得把所有虚拟vf都弄一遍

```sql
 ip link set em1 vf 1 spoofchk off
 ...
 ip link set em1 vf 7 spoofchk off

```
