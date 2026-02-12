---
title: ubuntu 安装远程桌面rdp配置中文
date: 2024-03-09 18:34:00
tags: ["系统", "Ubuntu", "Linux"]
categories: ["Linux", "Ubuntu"]
render_with_liquid: false
permalink: /posts/2024-03-09-ubuntu-安装远程桌面rdp配置中文/
---

本文档介绍 ubuntu 安装远程桌面rdp配置中文 的相关内容。

## 安装完成服务器版本后，安装桌面环境，使用精简的xfce4

```sql
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install xfce4
sudo apt install xfce4-session

```

## 安装xrdp用于支持远程rdp

```bash
sudo apt-get -y install xrdp
sudo systemctl enable xrdp

```

## 配置ssh支持root远程登陆

```bash
cat > /etc/ssh/sshd_config <<EOF
Port 22
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
SyslogFacility AUTHPRIV
PubkeyAuthentication yes
PermitRootLogin yes
AuthorizedKeysFile      .ssh/authorized_keys

# PasswordAuthentication yes

PasswordAuthentication yes
ChallengeResponseAuthentication no
GSSAPIAuthentication no
GSSAPICleanupCredentials no
UsePAM yes
X11Forwarding yes
UseDNS no
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF

systemctl restart sshd

```

## 授权用户admin证书访问，尽量不使用admin用户，会存在应用不能打开

```bash
# 填加用户

useradd -m -s /bin/bash admin
echo admin:Wangke0912|chpasswd
usermod -G sudo admin

sudo adduser admin ssl-cert
sudo adduser root ssl-cert

```

## 配置session,并加入环境变量

```bash
vim /etc/xrdp/startwm.sh

/// # 在第一个if后边加入echo这句
...
echo xfce4-session >~/.xsession
///

# 完成后在执行生成文件

echo xfce4-session >~/.xsession

```

## 重启服务

```bash
sudo service xrdp restart

```

## 配置用户密码，如果已配置忽略

```bash
sudo passwd admin

```

## 如果远程使用root用户不能正常登陆需要配置以下内容，配置完成后重启

```bash
# 需要注释以下两个文件，开头的第三行

vim /etc/pam.d/gdm-autologin

# auth required pam_succeed_if.so user != root quiet_success

vim /etc/pam.d/gdm-password

# auth required pam_succeed_if.so user != root quiet_success

# 修改/root/.profile文件

在最后一行mesg n 2> /dev/null || true
的前面加上tty -s&&后变为
tty -s&& mesg n 2> /dev/null || true

```

## 安装谷歌浏览器

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb

```
