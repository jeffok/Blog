---
title: nvmessd pci add
date: 2023-02-12 11:03:00
tags: ["脚本", "云计算", "Shell", "OpenStack", "Bash"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2023-02-12-nvmessd-pci-add/
---

本文档介绍 nvmessd pci add 的相关内容。

```bash
cat unbind_pci.sh

# !/bin/bash

# unbind pci ssd form host

echo "19e5 3714" > /sys/bus/pci/drivers/pci-stub/new_id
echo 0000:d8:00.0 > /sys/bus/pci/devices/0000:d8:00.0/driver/unbind
echo 0000:d8:00.0 > /sys/bus/pci/drivers/pci-stub/bind

# add xml

cat > /tmp/add_pci_nvme.xml <<EOF
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
     <address domain='0x0000' bus='0xd8' slot='0x00' function='0x0'/>
  </source>
</hostdev>
EOF

cat add_pci_nvme.xml
<hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
	<address domain='0x0000' bus='0xd8' slot='0x00' function='0x0'/>
      </source>
</hostdev>

cat attach_nvme.yml
---
hosts: nvme
  remote_user: inadm
  tasks:
name: attach nvme ssd to vms
      #shell: sudo virsh attach-disk {{vm|quote}} /dev/nvme0n1 vdb --cache none --subdriver raw --io native --persistent
      shell: sudo virsh attach-device {{vmname|quote}} /tmp/add_pci_nvme.xml --persistent

```
