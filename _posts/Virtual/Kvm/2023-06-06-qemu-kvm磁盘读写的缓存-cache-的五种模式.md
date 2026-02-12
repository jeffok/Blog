---
title: qemu-kvm磁盘读写的缓存（cache）的五种模式
date: 2023-06-06 17:57:00
tags: ["虚拟化", "QEMU", "KVM"]
categories: ["Virtual", "Kvm"]
render_with_liquid: false
permalink: /posts/2023-06-06-qemu-kvm磁盘读写的缓存-cache-的五种模式/
---

本文档介绍 qemu-kvm磁盘读写的缓存（cache）的五种模式 的相关内容。

```text
qemu-kvm磁盘读写的缓冲(cache)模式一共有五种，分别是
writethrough, wirteback, none, unsafe, directsync
当你对VM读写磁盘的性能有不同的要求的时候，你可以在其启动的参数(cache=xxxx)
里面进行一个合理的选择.
现在来简单说一说这五种模式的各自的特点(默认的是writeback)

cache=writethrough:
　　该模式对应的标志位是O_DSYNC，仅当数据被提交到了存储设备里面的时候，写操作
　　才会被完整的通告。此时host的页缓存可以被用在一种被称为writethrough缓存的模式。
　　guest的虚拟存储设备被告知没有回写缓存(writeback cache)，因此guest不需要为了
　　操纵整块数据而发送刷新缓存的指令了。此时的存储功能如同有一个直写缓存(writethrough cache)一样

cache=none:
　　所对应的标志位是O_DIRECT,在 none 模式下，VM的IO操作直接
　　在qemu-kvm的userspace缓冲和存储设备之间进行，绕开了host的页缓冲。
　　这个过程就相当于让vm直接访问了你的host的磁盘，从而性能得到了提升。

cache=writeback:
　　对应的标志位既不是 O_DSYNC 也不是 O_DIRECT ,在writeback模式下，IO操作会经过
　　host的页缓冲，存放在host页缓冲里的写操作会完整地通知给guest.
　　除此之外,guest的虚拟存贮适配器会被告知有回写缓存(writeback cache),所以为了能够
　　整体地管理数据，guest将会发送刷新缓存的指令.类似于带有RAM缓存的磁盘阵列(RAID)管理器.

cache=unsafe:
　　该模式与writeback差不多，不过从guest发出的刷新缓存指令将会被忽视掉，这意味着使用者
　　将会以牺牲数据的完整性来换取性能的提升。

cache=directsync:
　　该模式所对应的标志位是O_DSYNC和O_DIRECT,仅当数据被提交到了存储设备的时候，写
　　操作才会被完整地通告,并且可以放心地绕过host的页缓存。
　　就像writethrough模式,有时候不发送刷新缓存的指令时很有用的.该模式是最新添加的一种cache模式，
　　使得缓存与直接访问的结合成为了可能.

```
