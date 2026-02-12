---
title: ansible host及模块
date: 2020-05-17 18:22:00
tags: ["脚本", "自动化", "Ansible", "Shell"]
categories: ["Ansible"]
render_with_liquid: false
permalink: /posts/2020-05-17-ansible-host及模块/
---

本文档介绍 Ansible 主机清单（inventory）的定义方法和常用模块的使用。

## 主机清单定义

```ini
[test]
172.18.32.201
172.18.32.20[2:3]  # 表示 172.18.32.202 和 172.18.32.203

[test:vars]

# 组变量定义区域

```

```ini
# 指定用户和端口

[test]
172.18.32.201 ansible_ssh_user=wangyf  # 指定用户
172.18.32.201 ansible_ssh_user=wangyf ansible_ssh_port=8220  # 指定用户和端口

# 常用连接参数说明：
# ansible_ssh_user          # 指定 SSH 用户
# ansible_ssh_port          # 指定 SSH 端口
# ansible_ssh_host          # 指定被管理的主机地址
# ansible_ssh_private_key_file  # 指定私钥文件路径

# host_key_checking=False   # 跳过第一次远程连接需要输入 yes/no

```

## 使用方法

使用 `ping` 模块检查主机连通性：

```bash
ansible all -m ping   # 检查主机清单中所有组的主机存活
ansible test -m ping  # 检查主机清单中 test 组的主机存活

```

## 分组清单

```ini
# 使用 children 进行多机器分组

[mfs:children]
mfs_master
mfs_logger
mfs_node
mfs_client

[mfs_master]
172.18.32.201

[mfs_logger]
172.18.32.202

[mfs_node]
172.18.32.203

[mfs_client]
172.18.32.204

```

运行方法：

```bash
ansible mfs -m ping  # 对 mfs 组全部操作

```

## 常用模块及使用方法

### 查看模块列表和帮助

```bash

# 查看 ansible 所有模块

ansible-doc -l

# 查看指定模块的用法

ansible-doc -s user

```

### setup 模块

`setup` 模块主要用于获取主机信息，在 playbooks 中经常用到的 `gather_facts` 参数就与该模块相关。`setup` 模块下经常使用的一个参数是 `filter` 参数：

```bash

# 查看主机内存信息

ansible 10.212.52.252 -m setup -a 'filter=ansible_*_mb'

# 查看接口为 eth0-2 的网卡信息

ansible 10.212.52.252 -m setup -a 'filter=ansible_eth[0-2]'

# 将所有主机的信息输出到 /tmp/facts 目录下，每台主机的信息输出到主机名文件中

ansible all -m setup --tree /tmp/facts

```

## file模块

`file` 模块主要用于远程主机上的文件/目录操作，常用参数：

- `force`：强制创建软链接（源不存在但未来会创建；或目标软链已存在需要替换）
- `group`：属组
- `mode`：权限
- `owner`：属主
- `path`：路径（必填）
- `recurse`：递归设置目录属性（仅目录有效）
- `src`：链接源（`state=link` 时）
- `dest`：链接目标（`state=link` 时）
- `state`：
  - `directory`：创建目录
  - `file`：文件不存在也不创建
  - `link`：软链接
  - `hard`：硬链接
  - `touch`：创建/更新时间戳
  - `absent`：删除文件/目录或取消链接

使用示例：

```bash

# 创建软链接

ansible test -m file -a "src=/etc/fstab dest=/tmp/fstab state=link"

# 删除文件或目录

ansible test -m file -a "path=/tmp/fstab state=absent"

# 创建空文件或更新时间戳

ansible test -m file -a "path=/tmp/test state=touch"

```

## user/group 模块

> user模块是请求的是useradd, userdel, usermod三个指令，goup模块请求的是groupadd, groupdel, groupmod 三个指令。

`user` 模块常用参数：

- `home`：家目录（配合 `createhome`）
- `groups`：属组
- `uid`：uid
- `password`：密码（建议使用加密串）
- `name`：用户名
- `createhome`：是否创建家目录（`yes|no`）
- `system`：是否为系统用户
- `remove`：当 `state=absent` 时是否连同家目录删除（等价 `userdel -r`）
- `state`：创建/删除
- `shell`：shell

使用示例（命令行方式）：

```bash

# 创建用户并指定基本信息

ansible all -m user -a 'name=johnd comment="John Doe" uid=1040 group=admin'

# 创建用户并指定 shell 和附加组

ansible all -m user -a 'name=james shell=/bin/bash groups=admins,developers append=yes'

# 删除用户并删除家目录

ansible all -m user -a 'name=johnd state=absent remove=yes'

# 创建用户并指定过期时间

ansible all -m user -a 'name=james18 shell=/bin/zsh groups=developers expires=1422403387'

# 创建用户并生成 SSH 密钥

ansible all -m user -a 'name=test generate_ssh_key=yes ssh_key_bits=2048 ssh_key_file=.ssh/id_rsa'

```

> **注意**：指定 `password` 参数时，不建议使用明文密码，因为会写入目标主机 `/etc/shadow`。可先生成加密串：

```bash
echo "123456" | openssl passwd -1 -salt $(< /dev/urandom tr -dc '[:alnum:]' | head -c 32) -stdin

# 示例输出：

# $1$4P4PlFuE$ur9ObJiT5iHNrb9QnjaIB0

```

使用加密串创建用户：

```bash
ansible all -m user -a 'name=foo password="YOUR_PASSWORD"'

```

不同发行版默认加密方式可能不同，可查看 `/etc/login.defs` 确认（例如 CentOS 6.5 默认 SHA512）。

group 示例：

```yaml
ansible all -m group -a 'name=somegroup state=present'

```

## synchronize模块

`synchronize` 模块底层调用 `rsync` 同步文件，常用参数：

- `archive`：归档（递归、权限、时间、属主/组等），默认开启
- `checksum`：跳过检测 sum 值（默认关闭）
- `compress`：是否压缩
- `copy_links`：复制链接文件（默认为 no，另有 `links` 参数）
- `delete`：删除目标端多余文件（默认 no）
- `dest`：目标目录路径
- `dest_port`：目标端口（默认 22，SSH）
- `dirs`：只传目录不递归（默认 no）
- `rsync_opts`：额外 rsync 参数
- `set_remote_user`：当 ssh 用户与 rsync 用户不同时使用
- `mode`：`push`/`pull`

使用示例：

```bash

# 使用 sudo 执行 rsync

ansible all -m synchronize -a 'src=some/relative/path dest=/some/absolute/path rsync_path="sudo rsync"'

# 不使用归档模式，但复制链接文件

ansible all -m synchronize -a 'src=some/relative/path dest=/some/absolute/path archive=no links=yes'

# 启用校验和检查，但不同步时间戳

ansible all -m synchronize -a 'src=some/relative/path dest=/some/absolute/path checksum=yes times=no'

# 使用额外 rsync 参数，从远程拉取文件

ansible all -m synchronize -a 'src=/tmp/helloworld dest=/var/www/helloword rsync_opts=--no-motd,--exclude=.git mode=pull'

```

## filesystem 模块

在块设备上创建文件系统，常用选项：

- `dev`：目标块设备
- `force`：在已有文件系统的设备上强制创建
- `fstype`：文件系统类型
- `opts`：传递给 `mkfs` 命令的选项

示例：

```bash

# 强制在已有文件系统的设备上创建 ext2 文件系统

ansible test -m filesystem -a 'fstype=ext2 dev=/dev/sdb1 force=yes'

# 创建 ext4 文件系统并传递额外选项

ansible test -m filesystem -a 'fstype=ext4 dev=/dev/sdb1 opts="-cc"'

```

## mount 模块

配置挂载点，常用选项：

- `fstype`：挂载类型（必填）
- `name`：挂载点（必填）
- `opts`：传递给 `mount` 的参数
- `src`：要挂载的设备/源（必填）
- `state`：
  - `present`：只写入 fstab
  - `absent`：删除挂载点配置
  - `mounted`：创建挂载点并挂载
  - `umounted`：卸载

示例：

```bash

# 写入 fstab，使用设备路径挂载

ansible test -m mount -a 'name=/mnt/dvd src=/dev/sr0 fstype=iso9660 opts=ro state=present'

# 使用标签挂载

ansible test -m mount -a 'name=/srv/disk src="LABEL=SOME_LABEL" state=present'

# 使用 UUID 挂载

ansible test -m mount -a 'name=/home src="UUID=b3e48f45-f933-4c8e-a700-22a159ec9077" opts=noatime state=present'

# 创建 loop 设备并挂载示例

ansible test -a 'dd if=/dev/zero of=/disk.img bs=4k count=1024'
ansible test -a 'losetup /dev/loop0 /disk.img'
ansible test -m filesystem -a 'fstype=ext4 force=yes opts=-F dev=/dev/loop0'
ansible test -m mount -a 'name=/mnt src=/dev/loop0 fstype=ext4 state=mounted opts=rw'

```

## get_url模块

该模块主要用于从 http / ftp / https 服务器下载文件（类似 `wget`），常用选项：

- `sha256sum`：下载完成后做 sha256 校验
- `timeout`：下载超时时间（默认 10s）
- `url`：下载 URL
- `url_username` / `url_password`：需要用户名/密码认证时使用
- `use_proxy`：是否使用代理（代理需事先在环境变量中定义）

示例：

```bash

# 下载文件并设置权限

ansible all -m get_url -a 'url=http://example.com/path/file.conf dest=/etc/foo.conf mode=0440'

# 下载文件并校验 SHA256

ansible all -m get_url -a 'url=http://example.com/path/file.conf dest=/etc/foo.conf sha256sum=b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c'

```

## unarchive模块

用于解压文件，常用选项：

- `copy`：解压前是否先把文件复制到远程主机（默认 yes）。若为 no，要求目标主机压缩包已存在
- `creates`：指定一个文件名，若该文件存在则跳过解压
- `dest`：解压目标路径
- `group`：解压后目录/文件的属组
- `list_files`：是否列出压缩包内文件（默认 no）
- `mode`：解压后文件权限
- `src`：压缩包源路径（`copy=yes` 时需要）
- `owner`：解压后目录/文件的属主

示例：

```bash

# 解压本地文件到远程主机

ansible all -m unarchive -a 'src=foo.tgz dest=/var/lib/foo'

# 解压远程主机上已存在的文件

ansible all -m unarchive -a 'src=/tmp/foo.zip dest=/usr/local/bin copy=no'

# 从 URL 下载并解压

ansible all -m unarchive -a 'src=https://example.com/example.zip dest=/usr/local/bin copy=no'

```
