---
title: ubuntu rc.local 开机启动
date: 2020-09-25 17:33:00
tags: ["Systemd", "Ubuntu", "Linux"]
categories: ["Linux", "Ubuntu"]
render_with_liquid: false
permalink: /posts/2020-09-25-ubuntu-rc-local-开机启动/
---
vim /lib/systemd/system/rc-local.service

```ini
# 在文件最后增加以下内容

[Install]
WantedBy=multi-user.target
Alias=rc-local.service

```

vim /etc/rc.local

```yaml
填加想要开机启动的内容，内容如下

--------------------

# !/bin/bash

# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES

#

# It is highly advisable to create own systemd services or udev rules

# to run scripts during boot instead of using this file.

#

# In contrast to previous versions due to parallel execution during boot

# this script will NOT be run after all other services.

#

# Please note that you must run 'chmod +x /etc/rc.local' to ensure

# that this script will be executed during boot.

exit 0

--------------------

# 并增加可执行文件

chmod +x /etc/rc.local

systemctl daemon-reload
systemctl enable rc-local
systemctl start rc-local

```
