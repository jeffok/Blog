---
title: openstack kvm cannot set up guest memory pc.ram Cannot allocate memory
date: 2024-04-18 10:14:00
tags: ["虚拟化", "云计算", "OpenStack", "KVM"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2024-04-18-openstack-kvm-cannot-set-up-guest-memory-pc-ram-Ca/
---
Kvm：启动报错：error: internal error: process exited while connecting to monitor: 2018-11-12T01:47:14.993371Z qemu-system-x86_64: cannot set up guest memory 'pc.ram': Cannot allocate memory
今天有台kvm挂了，物理机启动时报错

很明显看报错显示内存不足，无法分配内存，查看物理机内存使用正常，.xml修改虚机内存后启动依然报错

## 报错

![image](http://note.youdao.com/yws/res/8640/3AE07702C84B4B9C93C8E1275CE4A03C)

这时候需要看一下主机确保可以分配多少内存

sysctl -a | grep overcommit
![image](http://note.youdao.com/yws/res/8642/FB3AA794C5BD446AABB8CEF8880AB106)

内核参数overcommit_memory
它是 内存分配策略

可选值：0、1、2。
0， 表示内核将检查是否有足够的可用内存供应用进程使用；如果有足够的可用内存，内存申请允许；否则，内存申请失败，并把错误返回给应用进程。
1， 表示内核允许分配所有的物理内存，而不管当前的内存状态如何。
2， 表示内核允许分配超过所有物理内存和交换空间总和的内存

什么是Overcommit和OOM
    Linux对大部分申请内存的请求都回复"yes"，以便能跑更多更大的程序。因为申请内存后，并不会马上使用内存。这种技术叫做Overcommit。当linux发现内存不足时，会发生OOM killer(OOM=out-of-memory)。它会选择杀死一些进程(用户态进程，不是内核线程)，以便释放内存。

    当oom-killer发生时，linux会选择杀死哪些进程？选择进程的函数是oom_badness函数(在mm/oom_kill.c中)，该函数会计算每个进程的点数(0~1000)。点数越高，这个进程越有可能被杀死。每个进程的点数跟oom_score_adj有关，而且oom_score_adj可以被设置(-1000最低，1000最高)。

## 解决方法

     很简单，按提示的操作（将vm.overcommit_memory 设为1）即可：

     有三种方式修改内核参数，但要有root权限：

   （1）编辑/etc/sysctl.conf ，改vm.overcommit_memory=1，然后sysctl -p 使配置文件生效

  （2）sysctl vm.overcommit_memory=1

  （3）echo 1 > /proc/sys/vm/overcommit_memory