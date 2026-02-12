---
title: centos7 使用bcache
date: 2024-06-28 15:55:00
tags: ["CentOS", "Git", "版本控制", "Linux"]
categories: ["Linux", "Centos7"]
render_with_liquid: false
permalink: /posts/2024-06-28-centos7-使用bcache/
---
简单介绍下bcache，bcache是linux内核块设备层的cache。主要是使用SSD盘在IO速度较慢的HDD盘上面做一层缓存，从而来提高HDD盘的IO速率。一个缓存设备(SSD)可以同时为多个后端设备(HDD)提供缓存。既然是缓存，那自然就会想到缓存策略，bcache支持三种缓存策略：

writeback：回写策略，所有的数据将先写入缓存盘，然后等待系统将数据回写入后端数据盘中。

writethrough：直写策略(默认策略)，数据将会同时写入缓存盘和后端数据盘。

writearoud：数据将直接写入后端磁盘。

bcache比较灵活，缓存策略可以随时修改，也可以针对不同的bcache设备设置不同的缓存策略。以下会按照安装、配置和使用这几个部分来说明具体使用bcache的过程。
https://lakelight.net/2017/12/20/centos7-bcache.html

https://www.itread01.com/content/1548985342.html  好的文档 ，包含所有bcache内容

https://ypdai.github.io/2018/07/13/bcache%E9%85%8D%E7%BD%AE%E4%BD%BF%E7%94%A8/

http://www.yangguanjun.com/2018/03/26/lvm-sata-ssd-bcache/

https://markrepo.github.io/maintenance/2018/09/10/bcache/

https://www.cnblogs.com/zimufeng/p/6640439.html    官方翻译说明文档

https://hgoldfish.com/blogs/article/106/  bcache 使用

https://evilpiepirate.org/git/bcache-tools.git

https://wiki.archlinux.org/index.php/Bcache_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

https://gist.github.com/mikulely/e2931b7cce388dbff006622a3eef7b42

http://qingqiuyuxiang.com/show.php?id=248

安装使用配置bcache

```bash
yum install git libuuid libuuid-devel libblkid-devel -y
git clone http://evilpiepirate.org/git/bcache-tools.git
cd bcache-tools/
make
make install

```

创建后端低速设备
我们把/dev/sdb配置为后端低速设备(一般是HDD、SATA盘等)

```routeros
[root@lab01 bcache-tools]# make-bcache -B /dev/sdb
UUID:            ac23506f-396d-4ac1-8949-d1e5c79ef207
Set UUID:        d40d7d90-d15f-4744-a56e-29d0ed5446f4
version:        1
block_size:        1
data_offset:        16

```

可以看到，在sdb(HDD)磁盘下，出现了bcache0节点，这个bcache0可以理解为就是/dev/sdb磁盘了

```bash
[root@lab01 bcache-tools]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   20G  0 disk
├─sda1            8:1    0  500M  0 part /boot
└─sda2            8:2    0 19.5G  0 part
  ├─centos-root 253:0    0 17.5G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
└─bcache0       252:0    0   20G  0 disk
sdc               8:32   0   20G  0 disk
sr0              11:0    1    4G  0 rom

```

现在，可以像普通磁盘一样，对bcache0进行格式化操作了。

```ini
[root@lab01 bcache-tools]# mkfs.xfs /dev/bcache0
meta-data=/dev/bcache0           isize=256    agcount=4, agsize=1310720 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=0        finobt=0
data     =                       bsize=4096   blocks=5242878, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[root@lab01 bcache-tools] mkdir /testbcache
[root@lab01 bcache-tools] mount /dev/bcache0 /testbcache
[root@lab01 bcache-tools]# df -h
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 2.0G     0  2.0G   0% /dev
tmpfs                    2.0G     0  2.0G   0% /dev/shm
tmpfs                    2.0G  8.6M  2.0G   1% /run
tmpfs                    2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/mapper/centos-root   18G  1.6G   16G   9% /
/dev/sda1                497M  170M  328M  35% /boot
tmpfs                    394M     0  394M   0% /run/user/0
/dev/bcache0              20G   33M   20G   1% /testbcache

```

创建前端缓存磁盘（SSD）
我们把/dev/sdc配置为前端高速设备(一般是SSD)

```routeros
[root@lab01 bcache-tools]#  make-bcache -C /dev/sdc
UUID:            9c5a00ff-4c32-4d0b-a6d2-ccd21e17e230
Set UUID:        8cae4fac-1312-4b0a-8bf7-2142dae5a334
version:        0
nbuckets:        40960
block_size:        1
bucket_size:        1024
nr_in_set:        1
nr_this_dev:        0
first_bucket:        1

```

建立映射关系
把我们创建好的后端低速设备和前端高速设备建立联系，这样高速设备才能为低速设备提供缓存作用。

首先需要获取该缓存盘(/dev/sdc)的cset.uuid，通过bcache-super-show命令查看：

```json
[root@lab01 bcache-tools]# bcache-super-show /dev/sdc
sb.magic        ok
sb.first_sector        8 [match]
sb.csum            D2BA585E4E51AD5C [match]
sb.version        3 [cache device]

dev.label        (empty)
dev.uuid        9c5a00ff-4c32-4d0b-a6d2-ccd21e17e230
dev.sectors_per_block    1
dev.sectors_per_bucket    1024
dev.cache.first_sector    1024
dev.cache.cache_sectors    41942016
dev.cache.total_sectors    41943040
dev.cache.ordered    yes
dev.cache.discard    no
dev.cache.pos        0
dev.cache.replacement    0 [lru]

cset.uuid        8cae4fac-1312-4b0a-8bf7-2142dae5a334

```

上面的cset.uuid后面的8cae4fac-1312-4b0a-8bf7-2142dae5a334就是我们需要的cset uuid，因为我们要和bcache0设备(也就是/dev/sdb设备)建立联系，从而是该缓存设备(/dev/sdc)，为bcache0设备提供缓存服务，所以执行下面命令

```bash
[root@lab01 bcache-tools]# echo "8cae4fac-1312-4b0a-8bf7-2142dae5a334" > /sys/block/bcache0/bcache/attach

```

操作完成后，可以通过lsblk命令查看结果

```bash
[root@lab01 bcache-tools]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   20G  0 disk
├─sda1            8:1    0  500M  0 part /boot
└─sda2            8:2    0 19.5G  0 part
  ├─centos-root 253:0    0 17.5G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
└─bcache0       252:0    0   20G  0 disk /testbcache
sdc               8:32   0   20G  0 disk
└─bcache0       252:0    0   20G  0 disk /testbcache
sr0              11:0    1    4G  0 rom

```

此时可以看到，sdc下也出现了bcache0设备，即表示缓存添加成功。还记得我们之前将bcache0(也就是/dev/sdb)挂载到了/testbcache目录下，此时如果对/testbcache进行读写操作时，bcache缓存设备就会起缓存作用了。

快速配置方式
上面我们配置大概分了三个步骤：创建后端设备、创建前端缓存设备、建立他们之间的映射关系。那有没有一步到位的方式，当然有。

```text
make-bcache -C /dev/sde -B /dev/sdb /dev/sdc /dev/sdd

```

上面这条命令，就自动的完成了那三个步骤，执行完看到的结果大概是这样的

```bash
...
sdb 254:16 0 50G 0 disk
└─bcache1 250:1 0 50G 0 disk
sdc 254:32 0 50G 0 disk
└─bcache0 250:0 0 50G 0 disk
sdd 254:48 0 50G 0 disk
└─bcache2 250:2 0 50G 0 disk
sde 254:64 0 10G 0 disk
├─bcache0 250:0 0 50G 0 disk
├─bcache1 250:1 0 50G 0 disk
└─bcache2 250:1 0 50G 0 disk
...

```

可以看到前端缓存设备sde同时为后端设备sdb、sdc、sdd提供缓存作用。

注：还可以在make-bcache的时候加入-w和-b参数，主要是提高缓存性能

- w block size 默认2K，一般需要block size = 后端设备的扇区大小。
- b bucket size，一般需要bucket size = 前端缓存设备的erase block size大小。*
修改缓存策略
查看缓存策略，可以看到默认的策略是writethrough，也就是直写模式

```bash
[root@lab01 bcache-tools]# cat /sys/block/bcache0/bcache/cache_mode
[writethrough] writeback writearound none

```

修改缓存策略

```bash
[root@lab01 bcache-tools]# echo writeback > /sys/block/bcache0/bcache/cache_mode

```

然后查看是否生效

```bash
[root@lab01 bcache-tools]# cat /sys/block/bcache0/bcache/cache_mode
writethrough [writeback] writearound none

```

注：就算机器重启之后缓存策略也不会失效的。

增加后端设备或前端缓存设备
有时候我们已经配置好了bcache，比如配置好了sde为sdb、sdc提供缓存作用，然后我现在想让sde为sdd也提供缓存作用。可以按照以下步骤进行：

配置后端设备：make-bcache -B /dev/sdd，假设生成bcache设备号为bcache2
建立映射关系：echo "8cae4fac-1312-4b0a-8bf7-2142dae5a334" > /sys/block/bcache2/bcache/attach
ok，完成。增加缓存设备也同理，先创建前端缓存设备，然后查看该缓存设备的cset uuid，然后根据cset uuid和后端设备建立映射关系即可。

恢复(还原到配置bcache之前)
我们经过上面的测试之后，也许我不需要bcache配置了，需要恢复到配置之前的环境，bcache肯定支持还原啦。

解除缓存盘和后端盘关系
要将缓存盘从当前的后端磁盘删除，只需将缓存盘的cset.uuid detach到bcache设备即可实现

```bash
[root@lab01 bcache-tools]# echo "8cae4fac-1312-4b0a-8bf7-2142dae5a334" > /sys/block/bcache0/bcache/detach
操作完成后，可以通过lsblk命令查看结果

[root@lab01 bcache-tools]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   20G  0 disk
├─sda1            8:1    0  500M  0 part /boot
└─sda2            8:2    0 19.5G  0 part
  ├─centos-root 253:0    0 17.5G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
└─bcache0       252:0    0   20G  0 disk /testbcache
sdc               8:32   0   20G  0 disk
sr0              11:0    1    4G  0 rom

```

可以看到sdc下面已经没有bcache0了。

删除前端缓存盘
这里要注意，在注销缓存盘前，要确认该缓存设备没有被任何的后端设备使用，否则你懂的，会有数据丢失的风险。

通过缓存盘的cset.uuid，在/sys/fs/bcache/<cset.uuid>/unregister写入1,即可进行注销操作

```bash
[root@lab01 bcache-tools]# echo 1 >/sys/fs/bcache/8cae4fac-1312-4b0a-8bf7-2142dae5a334/unregister

```

然后ls查看/sys/fs/bcache/，如果没有8cae4fac-1312-4b0a-8bf7-2142dae5a334这个目录，就表示注销成功了。

删除后端盘
同理，要删除后端缓存盘，首先需要解除该后端盘和它使用的缓存盘之间的映射关系

```bash
[root@lab01 bcache-tools]# umount /testbcache/
[root@lab01 bcache-tools]# echo 1 > /sys/block/bcache0/bcache/stop
[root@lab01 bcache-tools]# lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   20G  0 disk
├─sda1            8:1    0  500M  0 part /boot
└─sda2            8:2    0 19.5G  0 part
  ├─centos-root 253:0    0 17.5G  0 lvm  /
  └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
sdb               8:16   0   20G  0 disk
sdc               8:32   0   20G  0 disk
sr0              11:0    1    4G  0 rom

```

可以看到，环境已经恢复到配置bcache之前的了。
Bcache使用
下面在CentOS机器上，介绍如何使用bcache。
硬盘信息

```bash
# fdisk -l | grep dev

...
Disk /dev/vdb: 107.4 GB, 107374182400 bytes, 209715200 sectors
Disk /dev/vdc: 107.4 GB, 107374182400 bytes, 209715200 sectors
Disk /dev/vdd: 53.7 GB, 53687091200 bytes, 104857600 sectors

```

这里使用三块盘：vdb、vdc、vdd。
其中vdb、vdc是容量型磁盘，vdd是性能型磁盘，实验用vdd通过bcache加速vdb和vdc。
使用步骤
与bcache相关的命令有：make-bcache和bcache-super-show

```bash
# make-bcache

Please supply a device
Usage: make-bcache [options] device
C, --cache		Format a cache device
B, --bdev		Format a backing device
b, --bucket		bucket size
w, --block		block size (hard sector size of SSD, often 2k)
o, --data-offset	data offset in sectors
-cset-uuid		UUID for the cache set
-writeback		enable writeback
-discard		enable discards
-cache_replacement_policy=(lru|fifo)
h, --help		display this help and exit

# bcache-super-show

Usage: bcache-super-show [-f] <device>

```

创建backing device

```bash
# make-bcache -B /dev/vdb

UUID:            c602abab-bf5a-4b51-b7f6-1492d34239f4
Set UUID:        423e1910-f61a-45fa-8cdf-a23aca3b5eb8
version:        1
block_size:        1
data_offset:        16

# bcache-super-show /dev/vdb

sb.magic		ok
sb.first_sector		8 [match]
sb.csum			1376BA45B5F924B [match]
sb.version		1 [backing device]

dev.label		(empty)
dev.uuid		c602abab-bf5a-4b51-b7f6-1492d34239f4
dev.sectors_per_block	1
dev.sectors_per_bucket	1024
dev.data.first_sector	16
dev.data.cache_mode	0 [writethrough]
dev.data.cache_state	1 [clean]

cset.uuid		4b60c663-7720-4dea-a17a-e9316078e796

```

创建cache device

```bash
# make-bcache -C /dev/vdd

UUID:            050998ce-403c-45d7-a89b-492379644c1b
Set UUID:        4b60c663-7720-4dea-a17a-e9316078e796
version:        0
nbuckets:        102400
block_size:        1
bucket_size:        1024
nr_in_set:        1
nr_this_dev:        0
first_bucket:        1

# bcache-super-show /dev/vdd

sb.magic        ok
sb.first_sector        8 [match]
sb.csum            68CDDDC337A2E296 [match]
sb.version        3 [cache device]

dev.label        (empty)
dev.uuid        050998ce-403c-45d7-a89b-492379644c1b
dev.sectors_per_block    1
dev.sectors_per_bucket    1024
dev.cache.first_sector    1024
dev.cache.cache_sectors    104856576
dev.cache.total_sectors    104857600
dev.cache.ordered    yes
dev.cache.discard    no
dev.cache.pos        0
dev.cache.replacement    0 [lru]

cset.uuid        4b60c663-7720-4dea-a17a-e9316078e796

```

绑定backing device到cache device

```bash
# echo "4b60c663-7720-4dea-a17a-e9316078e796" > /sys/block/bcache0/bcache/attach

# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk
vdc       253:32   0  100G  0 disk
vdd       253:48   0   50G  0 disk
└─bcache0 251:0    0  100G  0 disk

```

查看bcache相关信息

```bash
# state

# cat /sys/block/bcache0/bcache/state

clean

```

state的几个状态：

- no cache：该backing device没有attach任何caching device
- clean：一切正常，缓存是干净的
- dirty：一切正常，已启用回写，缓存是脏的
- inconsistent：遇到问题，后台设备与缓存设备不同步
2、缓存数据量

```bash
# cat /sys/block/bcache0/bcache/dirty_data

0. 0k

```

3、缓存模式

```bash
# cat /sys/block/bcache0/bcache/cache_mode

[writethrough] writeback writearound none

# echo writearound > /sys/block/bcache0/bcache/cache_mode

# cat /sys/block/bcache0/bcache/cache_mode

writethrough writeback [writearound] none

```

4、writeback信息

```bash
# cat /sys/block/bcache0/bcache/writeback_

writeback_delay                writeback_percent              writeback_rate_debug           writeback_rate_p_term_inverse  writeback_running
writeback_metadata             writeback_rate                 writeback_rate_d_term          writeback_rate_update_seconds

```

解绑backing device的cache device

```bash
# echo "697b764f-b3ef-4675-8761-d9518a12089c" > /sys/block/bcache0/bcache/detach

# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk
vdc       253:32   0  100G  0 disk
vdd       253:48   0   50G  0 disk

# cat /sys/block/vdb/bcache/state

no cache

```

解绑后设备可以继续使用，只是没有cache device的加速

添加新backing device

```bash
# make-bcache -B /dev/vdc

UUID:            cc790e62-b3eb-4237-8265-dd1b619e15c0
Set UUID:        edb2b1d0-9eeb-4a8a-b811-3dafd676fac0
version:        1
block_size:        1
data_offset:        16

# echo "4b60c663-7720-4dea-a17a-e9316078e796" > /sys/block/bcache1/bcache/attach

# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk
vdc       253:32   0  100G  0 disk
└─bcache1 251:1    0  100G  0 disk
vdd       253:48   0   50G  0 disk
└─bcache1 251:1    0  100G  0 disk

```

使用bcache device

```bash
# mkfs.ext4 /dev/bcache1

# mount /dev/bcache1 /mnt/

# df -h

Filesystem      Size  Used Avail Use% Mounted on
...
/dev/bcache1     99G   61M   94G   1% /mnt

# umount /mnt/

```

注销bcache device

```bash
# echo 1 > /sys/block/vdc/bcache/stop

# echo 1 > /sys/block/vdb/bcache/stop

# echo 1 > /sys/fs/bcache/10057a1c-15a2-4631-a6d2-f4652d37645d/unregister

# lsblk

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb    253:16   0  100G  0 disk
vdc    253:32   0  100G  0 disk
vdd    253:48   0   50G  0 disk

```

echo的数字不重要，可为任何值 ;)

快捷创建bcache device

```bash
# make-bcache -B /dev/vdb /dev/vdc -C /dev/vdd

UUID:			09f971eb-6063-4f94-bdac-d7d7117c0e0f
Set UUID:		697b764f-b3ef-4675-8761-d9518a12089c
version:		0
nbuckets:		102400
block_size:		1
bucket_size:		1024
nr_in_set:		1
nr_this_dev:		0
first_bucket:		1
UUID:			b45301fa-8932-4194-9518-ab681f37d9c9
Set UUID:		697b764f-b3ef-4675-8761-d9518a12089c
version:		1
block_size:		1
data_offset:		16
UUID:			2c0452f7-76de-4319-bd3c-2a73b4fa4b68
Set UUID:		697b764f-b3ef-4675-8761-d9518a12089c
version:		1
block_size:		1
data_offset:		16
[root@lvm-centos-tst ~]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk
vdc       253:32   0  100G  0 disk
└─bcache1 251:1    0  100G  0 disk
vdd       253:48   0   50G  0 disk
├─bcache0 251:0    0  100G  0 disk
└─bcache1 251:1    0  100G  0 disk

```

遇到的问题
make-bcache命令有提示
之前做过bcache的device，重做bcache有提示

```bash
# make-bcache -B /dev/vdb

Already a bcache device on /dev/vdb, overwrite with --wipe-bcache

# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk

```

虽说有提示，但实际bcache device已经创建成果
针对上述情况，可以通过写device前一部分数据的方法解决
可以通过dd命令来清理device的前部分数据：

```bash
# dd if=/dev/zero of=/dev/vdb bs=1M count=100 oflag=direct

# dd if=/dev/zero of=/dev/vdd bs=1M count=100 oflag=direct

```

再创建bcache device，就不会报错了：

```bash
# make-bcache -B /dev/vdb

UUID:            c602abab-bf5a-4b51-b7f6-1492d34239f4
Set UUID:        423e1910-f61a-45fa-8cdf-a23aca3b5eb8
version:        1
block_size:        1
data_offset:        16

# make-bcache -C /dev/vdd

UUID:            050998ce-403c-45d7-a89b-492379644c1b
Set UUID:        4b60c663-7720-4dea-a17a-e9316078e796
version:        0
nbuckets:        102400
block_size:        1
bucket_size:        1024
nr_in_set:        1
nr_this_dev:        0
first_bucket:        1

```

设备没umount就直接注销
没有umount，注销bcache device后，设备依旧可以使用，umount后设备消失

```bash
# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk /mnt
vdc       253:32   0  100G  0 disk
vdd       253:48   0   50G  0 disk
└─bcache0 251:0    0  100G  0 disk /mnt

# mount | grep bcache

/dev/bcache0 on /mnt type ext4 (rw,relatime,seclabel,data=ordered)

# echo 1 > /sys/fs/bcache/4b60c663-7720-4dea-a17a-e9316078e796/unregister

# echo 0 > /sys/block/vdb/bcache/stop

# lsblk

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb       253:16   0  100G  0 disk
└─bcache0 251:0    0  100G  0 disk /mnt
vdc       253:32   0  100G  0 disk
vdd       253:48   0   50G  0 disk

# ls /sys/block/vdb/bcache

ls: cannot access /sys/block/vdb/bcache: No such file or directory

# cd /mnt/

# touch tstfile

# umount  /mnt/

# lsblk

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
...
vdb    253:16   0  100G  0 disk
vdc    253:32   0  100G  0 disk
vdd    253:48   0   50G  0 disk

```
