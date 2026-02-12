---
title: iptstate命令-以top风格显示内核的iptables状态
date: 2023-01-03 13:53:00
tags: ["系统", "Linux"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2023-01-03-iptstate命令-以top风格显示内核的iptables状态/
---
iptstate命令以top命令类似的风格实时显示Linux内核中iptables的工作状态。输出信息可以以任何字段进行排序，可以定义状态刷新的频率和单次显示状态信息。

> https://www.linuxcool.com/iptstate

## 语法格式：iptstate [参数]

## 常用参数

| 参数 | 说明 |
| --- | --- |
| - b | 指定输出信息的排序规则 |
| - d | 不动态的改变窗口大小 |
| - f | 过滤本地回送消息 |
| - h | 显示帮助消息 |
| - l | 将IP地址解析为域名 |
| - L | 隐藏于DNS查询相关的状态 |
| - r <秒数> | 指定刷新屏幕的频率 |
| - R | 反序排序 |
| - s | 单次运行模式，仅打印一次状态信息 |
| - t | 显示汇总信息 |

## 参考实例

以top风格实时显示iptables的工作状态：

```json
[root@linuxcool ~]# iptstate

```

显示汇总消息:

```json
[root@linuxcool ~]# iptstate -t

```

指定屏幕刷新的频率为5秒：

```json
[root@linuxcool ~]# iptstate -r 5

```

打印状态信息：

```json
[root@linuxcool ~]# iptstate -s

```
