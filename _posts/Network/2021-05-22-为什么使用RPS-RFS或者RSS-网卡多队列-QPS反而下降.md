---
title: 为什么使用RPS-RFS或者RSS-网卡多队列,QPS反而下降
date: 2021-05-22 16:32:00
tags: ["网络"]
categories: ["Network"]
render_with_liquid: false
permalink: /posts/2021-05-22-为什么使用RPS-RFS或者RSS-网卡多队列-QPS反而下降/
---

本文档介绍 为什么使用RPS-RFS或者RSS-网卡多队列,QPS反而下降 的相关内容。

<>### 介绍

* RSS<br>
即receive side steering,利用网卡的多队列特性，将每个核分别跟网卡的一个首发队列绑定，以达到网卡硬中断和软中断均衡的负载在各个CPU上。<br>
他要求网卡必须要支持多队列特性。<br>

* RPS<br>
receive packet steering<br>
他把收到的packet依据一定的hash规则给hash到不同的CPU上去，以达到各个CPU负载均衡的目的。<br>
他只是把软中断做负载均衡，不去改变硬中断。因而对网卡没有任何要求。

* RFS <br>
receive flow steering<br>
RFS需要依赖于RPS，他跟RPS不同的是不再简单的依据packet来做hash，而是根据flow的特性，即application在哪个核上来运行去做hash，从而使得有更好的数据局部性。

我们可以看到很多案例，使用这些特性后提醒了网络包的处理能力，从而提升QPS，降低RT。

但是，我们知道，任何一个优化特性都不是普遍适用的，都有他特定的场景来应用。
很多人对此可能会有疑惑，那很多优化功能不是都已经作为默认配置了么，如果不是普遍适用的，干嘛还要作为默认配置呢？
其实很简单，一个优化特性可以作为默认配置，依据我的理解，只需要满足下面这些特征即可：

* 对某些场景可以显著提升性能
* 对大部分场景无害
* 对某一部分场景可能会损伤性能

所以Linux的很多配置都是可以灵活配置供选择的。

下面我们就来看下RPS这些特性在哪些场景下才能发挥作用。

### 问题描述

业务方在使用KVM虚拟机进行性能压测时，发现某一个核的softirq占比特别高，如下所示：

```text
$ mpstat -P ALL 1
03:44:20 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
03:44:21 PM  all   68.58    0.00   20.70    0.00    0.00    5.49    0.00    0.00    0.00    5.24
03:44:21 PM    0   70.00    0.00   23.00    0.00    0.00    0.00    0.00    0.00    0.00    7.00
03:44:21 PM    1   60.78    0.00   16.67    0.00    0.00   21.57    0.00    0.00    0.00    0.98
03:44:21 PM    2   71.29    0.00   21.78    0.00    0.00    0.00    0.00    0.00    0.00    6.93
03:44:21 PM    3   73.74    0.00   21.21    0.00    0.00    0.00    0.00    0.00    0.00    5.05

```

一句话解释：这个kvm虚拟机只有一个网卡，有网络包到达这个网卡后，它会给某一个cpu(如果没有设置亲和性，这个可以认为是随机的一个cpu，然后就会一直固定在这个cpu上)发中断，通知该cpu来处理这个包，然后cpu就会触发一个软中断把该包送到tcp/ip协议栈(对于tcp包而言)里去处理，该包被放入某一个socket的receive buffer中（如果是一个数据包），软中断结束。<br>
%soft就是指的CPU耗在软中断处理上的时间。<br>
可以看到核1的%soft很高，其他的核的%soft基本为0.<br>
所以就想着把核1的%soft给均摊下，是否可以提升QPS。<br>
我们想到的方法是网卡多队列，或者RPS／RFS。用这种手段来把网卡软中断给均摊到其他的核上去。

其实，看到前面mpstat的显示，如果对网卡多队列，RPS／RFS很熟悉，就会意识到他们在这里不适用。

使用网卡多队列后，果然是QPS不但没有提升，反而有下降。

为了使描述更清晰（其实是因为我做分析的这个kvm虚拟机上没有网卡多队列，但是不影响，导致性能下降的原因是一致的），我们只分析RPS来看下为什么性能会下降。

### RPS的原理概述

* 基于CentOS-7 <br>
<img src="http://note.youdao.com/yws/res/5493/3DE6DF483B6542E197F93118B02C67D2" width=600 />
在这之前，软中断只能在硬中断所在CPU上处理，使用RPS后，网卡软中断就可以分发到其他的CPU上去做处理了。

### 使用RPS后为什么会导致QPS下降？

如上图所示，使能了RPS后，会增加一些额外的CPU开销：

1. 收到网卡中断的CPU会向其他CPU发IPI中断，这体现在CPU的%irq上
2. 需要处理packet的cpu会收到NET_RX_SOFTIRQ软中断，这体现再CPU的%soft上。请注意，RPS并不会减少第一个CPU的软中断次数，但是会额外给其他的CPU增加软中断。他减少的是第一个CPU的软中断的执行时间，即，软中断里不再需要那么多的时间去走协议栈做包解析，把这个时间给均摊到其他的CPU上去了。

### 量化对比数据

硬中断次数的变化<br>
这可以通过/proc/interrupts来观察

```bash
$ watch -d -n 1 'cat /proc/interrupts'

```

* 使用RPS之后：<br>
<img src="http://note.youdao.com/yws/res/5508/816B6AFCCFBA4A248DCCC535491B5D76" width=600 />

* 使用RPS之前:<br>
<img src="http://note.youdao.com/yws/res/5512/C22E27824E1B4C8B91657D9242AFE79B" width=600 />
可以看到，是能RPS后，增加了很多的Function call interrups，即IPI。<br>
而virtio0-input.0（虚拟网卡产生的中断，类似于图中NIC产生的中断）仍然只发给CPU1.<br>
也可以通过dstat来看整体次数的对比<br>

* 使用RPS之后：<br>

```sql
$ dstat
You did not select any stats, using -cdngy by default.

---total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw
 62  23   4   0   0  12|   0     0 |7096k   11M|   0     0 |  49k 2261
 74  13   4   0   0   9|   0     0 |4003k 6543k|   0     0 |  31k 2004
 59  22   5   0   0  13|   0  4096B|6710k   10M|   0     0 |  48k 2220

```

* 使用RPS之前：<br>

```sql
$ dstat
You did not select any stats, using -cdngy by default.

---total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw
 64  23   6   0   0   7|   0  8192B|7917k   12M|   0     0 |  27k 1922
 64  22   6   0   0   8|   0     0 |7739k   12M|   0     0 |  26k 2210
 61  23   9   0   0   7|   0     0 |7397k   11M|   0     0 |  25k 2267
 94   4   0   0   0   1|   0     0 |1262k

```

软中断次数的变化<br>
这可以通过/proc/softirq来观察<br>

```bash
$ watch -d -n 1 'cat /proc/softirq'

```

* 使用RPS之前：<br>
<img src="http://note.youdao.com/yws/res/5526/ED32577438EA46C2A3FD61E0CA953ACD" width=600 />

* 使用RPS之后：<br>
<img src="http://note.youdao.com/yws/res/5530/F092CBB1C4654DE78CC1C65442E72990" width=600 />

可以看到，CPU1上的RX_NET数相差不大比较接近，但是CPU0/2/3上各自都增加了NET_RX.

各个CPU利用率的变化<br>
这可以通过mpstat来观察<br>

```text
$ mpstat -P ALL 1

```

* 使用RPS之后

```text
Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   66.21    0.00   17.73    0.00    0.00   11.15    0.00    0.00    0.00    4.91
Average:       0   68.17    0.00   18.33    0.00    0.00    7.67    0.00    0.00    0.00    5.83
Average:       1   60.57    0.00   15.81    0.00    0.00   20.80    0.00    0.00    0.00    2.83
Average:       2   69.95    0.00   19.20    0.00    0.00    7.01    0.00    0.00    0.00    3.84
Average:       3   66.39    0.00   17.64    0.00    0.00    8.99    0.00    0.00    0.00    6.99

```

* 使用RPS之前

```text
Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   70.18    0.00   19.28    0.00    0.00    5.86    0.00    0.00    0.00    4.68
Average:       0   73.25    0.00   21.50    0.00    0.00    0.00    0.00    0.00    0.00    5.25
Average:       1   58.85    0.00   14.46    0.00    0.00   23.44    0.00    0.00    0.00    3.24
Average:       2   74.50    0.00   20.00    0.00    0.00    0.00    0.00    0.00    0.00    5.50
Average:       3   74.25    0.00   21.00    0.00    0.00    0.00    0.00    0.00    0.00    4.75

```

可以看到，整体而言，CPU的%soft增大了很多，%usr下降了一些。<br>
我们知道%usr是衡量用户态程序性能的一个指标，%usr越高，意味着执行业务代码的时间就越多。如果%usr下降，那就意味着执行业务代码的时间变少了，这显然对于业务性能是一个危险信号。<br>
至于%usr里面如何来提高业务代码执行效率，是另外的问题了，不讨论。<br>

### 结论，RPS适用的场景

使用了RPS后，会增加CPU的%soft，如果业务场景本身就是CPU密集的，CPU的负载已经很高了，那么RPS就会挤压%usr，即挤压业务代码的执行时间，从而导致业务性能下降。<br>

##### 适用场景

RPS如果想要提升业务性能，前提是除了网卡中断所在的CPU外，其他的CPU都需要有一定的空闲时间，这样使能RPS才能带来收益，否则就会带来额外开销导致性能下降。<br>
在这个场景下，RPS搭配RFS会带来更好的收益，不讨论。<br>

##### 有没有更优的解决方案？

答案肯定是有的。