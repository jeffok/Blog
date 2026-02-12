---
title: linux 查看历史命令history
date: 2022-09-08 10:26:00
tags: ["Git", "版本控制", "系统", "Linux"]
categories: ["Linux"]
render_with_liquid: false
permalink: /posts/2022-09-08-linux-查看历史命令history/
---

本文档介绍 linux 查看历史命令history 的相关内容。

查看历史命令

```text
history

```

显示3行历史命令

```text
history 3

```

执行第几行命令

- !number执行第几行命令
- !command 从最近的命令查到以command开头的命令执行
- !!执行上一条命令

- !100 执行第100行命令

## history 修改配置文件

查看当前记录历史命令的行数

```bash
echo $HISTSIZE

# 1000 默认为1000行

```

修改记录的行数

```ini
vim /etc/profile
HISTSIZE=1000
export HISTSIZE

```

想让linux的history命令显示时间

```bash
vim /etc/profile
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S]>> "

# 989  [2020-02-16 21:20:57]>> ping git.jeffok.com

```
