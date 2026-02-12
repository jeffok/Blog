---
title: ubuntu btctools 服务器
date: 2020-12-17 10:26:00
tags: ["Ubuntu", "Linux", "容器", "Docker"]
categories: ["Linux", "Ubuntu"]
render_with_liquid: false
permalink: /posts/2020-12-17-ubuntu-btctools-服务器/
---

本文档介绍 ubuntu btctools 服务器 的相关内容。

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

## 安装btctools

```bash
sudo snap install btctools

```

## 安装docker和docker-compose

```bash
# 安装静态软件源

sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 安装证书

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 填加源

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装docker

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# 脚本快速安装docker

sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

安装docker-compose
curl -SL https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

```

## 启动dns和时间服务器

### docker-compose.yml

```yaml
version: "3.3"
services:
  coredns:
    image: reg.jeffok.com/opssys/coredns:latest
    container_name: coredns
    restart: always
    volumes:
./Corefile:/usr/local/coredns/Corefile
    network_mode: "host"
    command:
-conf
Corefile
  smartdns:
    image: reg.jeffok.com/opssys/smartdns:latest
    container_name: smartdns
    restart: always
    volumes:
./Smartfile:/usr/local/smartdns/Smartfile
./smartdns.log:/var/log/smartdns.log:rw
    network_mode: "host"
    command:
-c
Smartfile
-f
  ntp:
    image: reg.jeffok.com/opssys/ntp:latest
    container_name: ntp
    restart: always
    ports:
123:123/udp
    tmpfs:
/etc/chrony:rw,mode=1750
/run/chrony:rw,mode=1750
/var/lib/chrony:rw,mode=1750
    environment:
NTP_SERVERS=time.cloudflare.com,time.google.com
LOG_LEVEL=0
    volumes:
/etc/localtime:/etc/localtime:ro

```

### Smartfile

```bash
bind 127.0.0.1:5311 -group int -no-speed-check
bind-tcp 127.0.0.1:5311 -group int -no-speed-check

bind 127.0.0.1:5322  -no-speed-check -group ext -no-speed-check
bind-tcp 127.0.0.1:5322  -no-speed-check -group ext -no-speed-check

cache-size 5120
prefetch-domain yes
rr-ttl-min 60
rr-ttl-max 100
rr-ttl 100
-log-level error
log-file /var/log/smartdns.log

# int-dns

# server 1.2.3.4 -group int

# server 1.2.3.4 -group int

server 1.2.3.4 -group int
server 1.2.3.4 -group int

# server 1.2.3.4 -group int

# server-tls rubyfish.cn -no-check-certificate -group int

# server-https https://doh.360.cn/dns-query  -no-check-certificate -group int

# ext-dns

server 1.2.3.4 -exclude-default-group -group ext
server 1.2.3.4 -exclude-default-group -group ext

# server 1.2.3.4  -exclude-default-group -group ext

# server-tcp 1.2.3.4 -exclude-default-group -group ext

# server-https https://doh.opendns.com/dns-query -exclude-default-group -no-check-certificate -group ext

# server-https https://cloudflare-dns.com/dns-query -exclude-default-group -no-check-certificate -group ext

# server-https https://dns9.quad9.net/dns-query -exclude-default-group -no-check-certificate -group ext

```

### update.sh

```ini
# !/bin/bash

O_MD5=796da7e766e7ab58bd52ace569236acf

china=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`
apple=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/apple.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`
bogus=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf | grep "=" | while read line; do awk -F '=' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`

# google=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/google.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`

cat>Corefile<<EOF
. {
    hosts {

	192. 168.153.222 time.cloudholy.com
	192. 168.151.222 time.cloudholy.com
        192. 168.151.225 mirrors.cloudholy.com
        192. 168.151.225 harbor.jointdc.com
        fallthrough
    }
    forward . 127.0.0.1:5322 {
    except $china $apple cdn.jsdelivr.net api2.mch.weixin.qq.com api2.weixin.qq.com api.mch.weixin.qq.com api.weixin.qq.com axshort.weixin.qq.com btrace.qq.com c6.y.qq.com cnc.qzone.qq.com connect.qq.com dl.wechat.com dns.weixin.qq.com.cn emoji.qpic.cn extshort.weixin.qq.com file.api.weixin.qq.com file.wx.qq.com findershort.weixin.qq.com fraud.mch.weixin.qq.com game.qq.com graph.qq.com gtimg.cn gtimg.com hk.api.weixin.qq.com hkaxshort.weixin.qq.com hkdisas.weixin.qq.com hkextshort.weixin.qq.com hkfindershort.weixin.qq.com hklong.weixin.qq.com hkminorshort.weixin.qq.com hkquic.weixin.qq.com hkshort6.weixin.qq.com hkshort.pay.weixin.qq.com hkshort.weixin.qq.com hksupport.weixin.qq.com imgcache.qq.com i.qq.com live.qq.com long.weixin.qq.com mail.qq.com mch.weixin.qq.com minorlong.weixin.qq.com minorshort.weixin.qq.com mlaxshort.weixin.qq.com mldisas.weixin.qq.com mlextshort.weixin.qq.com mlfindershort.weixin.qq.com mllong.weixin.qq.com mlminorlong.weixin.qq.com mlminorshort.weixin.qq.com mlquic.weixin.qq.com mlshort.pay.weixin.qq.com mlshort.weixin.qq.com mlsupport.weixin.qq.com mmbiz.qlogo.cn mmbiz.qpic.cn mmbizwechat.com mmpay.com mmsns.qpic.cn mp.weixinbridge.com mp.weixin.qq.com mp.wework.cn mqqapi.com myapp.com myqcloud.com now.qq.com open.qq.com open.weixin.qq.com pay.qq.com pingfore.qq.com qlogo.cn qmail.qq.com qpic.cn qq.com qqmail.com quic.weixin.qq.com qyapi.weixin.qq.com qzone.com qzone.qq.com qzonestyle.gtimg.cn qzs.qq.com res.servicewechat.com resstatic.servicewechat.com res.wx.qq.com servicewechat.com sgaxshort.wechat.com sgfindershort.wechat.com sgilinkshort.wechat.com sglong.wechat.com sgminorshort.wechat.com sgshort.pay.wechat.com sgshort.wechat.com sh.api.weixin.qq.com shdisas.weixin.qq.com shextshort.weixin.qq.com shminorlong.weixin.qq.com shmmsns.qpic.cn short.pay.weixin.qq.com short.weixin.qq.com shp.qlogo.cn shquic.weixin.qq.com shshort.pay.weixin.qq.com support.weixin.qq.com sz.api.weixin.qq.com szaxshort.weixin.qq.com szdisas.weixin.qq.com szextshort.weixin.qq.com szfindershort.weixin.qq.com szlong.weixin.qq.com szminorlong.weixin.qq.com szminorshort.weixin.qq.com szmmsns.qpic.cn szquic.weixin.qq.com szshort.pay.weixin.qq.com szshort.weixin.qq.com szsupport.weixin.qq.com tencent-cloud.com tencent-cloud.net tencent.com tencentcs.com tencentmap.wechat.com tencentmind.com tenpay.com tenpay.qq.com video.gtimg.com vip.qq.com v.qq.com vweixinf.tc.qq.com web.wechat.com wechat.com wechatlegal.net wechatpay.com weixin110.qq.com weixinbridge.com weixinc2c.tc.qq.com weixin.com weixin.qq.com weixinsxy.com weiyun.com wx2.qq.com wx8.qq.com wxapp.qq.com wxapp.tc.qq.com wx.gtimg.com wximg.qq.com wx.qlogo.cn wx.qq.com wxsnsdythumb.wxs.qq.com wxsnsdyvip.wxs.qq.com wxsnsdy.wxs.qq.com y.qq.com y.qqmusic.com
    }
    proxy . 127.0.0.1:5311
    bogus $bogus
    cache 10
    health
    reload
    errors
}
EOF

N_MD5=`md5sum Corefile|awk '{print $1}'`

[[ "$O_MD5" == "$N_MD5" ]] && exit 0 || docker-compose restart coredns

sed -ri "/^O_MD5/c O_MD5=$N_MD5" $0

```

### update.sh_includelog

```ini
# !/bin/bash

O_MD5=86da79f6d3586595dc5aaa4c9a248f26

china=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`
apple=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/apple.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`
bogus=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf | grep "=" | while read line; do awk -F '=' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`

# google=`curl -sSL https://github.com/felixonmars/dnsmasq-china-list/raw/master/google.china.conf | while read line; do awk -F '/' '{print $2}' | grep -v '#' ; done |  paste -sd " " -`

cat>Corefile<<EOF
. {
    hosts {

	192. 168.153.222 time.cloudholy.com
	192. 168.151.222 time.cloudholy.com
        192. 168.151.225 mirrors.cloudholy.com
        192. 168.151.225 harbor.jointdc.com
        fallthrough
    }
    forward . 127.0.0.1:5322 {
    except $china $apple cdn.jsdelivr.net
    }
    proxy . 127.0.0.1:5311
    bogus $bogus
    cache 10
    log
    health
    reload
    errors
}
EOF

N_MD5=`md5sum Corefile|awk '{print $1}'`

[[ "$O_MD5" == "$N_MD5" ]] && exit 0 || docker-compose restart coredns

sed -ri "/^O_MD5/c O_MD5=$N_MD5" $0

```
