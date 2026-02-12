---
title: mac安装virtualenv和virtualenvwrapper python虚拟环境
date: 2021-10-03 12:16:00
tags: ["Homebrew", "Mac", "macOS"]
categories: ["Mac"]
render_with_liquid: false
permalink: /posts/2021-10-03-mac安装virtualenv和virtualenvwrapper-python虚拟环境/
---

本文档介绍 mac安装virtualenv和virtualenvwrapper python虚拟环境 的相关内容。

## 首先安装virtualenv和virtualenvwrapper

```text
brew install virtualenv
brew install virtualenvwrapper

```

## 查找virtualenvwrapper.sh的位置

```text
which virtualenvwrapper.sh

```

## 加入环境变量/Users/jeff/.bash_profile,在最后加入

```ini
export WORKON_HOME=/Users/jeff/Project/Pyenv
source /usr/local/bin/virtualenvwrapper.sh

```

## 导入立即生效

```bash
source ~/.bash_profile

```

## 创建虚拟环境

```text
mkvirtualenv test

```

## 其它命令

- workon 显示所有的环境名称
- workon 环境名 进入/切换到该环境
- deactivate 返回到系统环境
- rmvirtualenv 移除环境

## 创建python3环境

```bash
virtualenv -p /usr/local/bin/python3 Pydevpi

```

## 进入python3环境

```bash
source Pydevpi/bin/activate

```
