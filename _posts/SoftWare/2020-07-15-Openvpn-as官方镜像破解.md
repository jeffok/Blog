---
title: Openvpn-as官方镜像破解
date: 2020-07-15 11:51:00
tags: ["VPN", "容器", "网络", "OpenVPN", "Docker"]
categories: ["SoftWare"]
render_with_liquid: false
permalink: /posts/2020-07-15-Openvpn-as官方镜像破解/
---

## 使用docker下载官方镜像并使用启动copy需要破解的文件

1. 运行openvpn-as的容器镜像并确认文件名称：

```bash
# 下载镜像

docker pull openvpn/openvpn-as:2.12.1-bc070def-Ubuntu22

# 4e925fc5e52c 是openvpn-as的镜像ID

docker run -it 4e925fc5e52c /bin/bash

# 确认文件名称，如果文件名称的版本不一样请修改

ls -l /usr/local/openvpn_as/lib/python/pyovpn-2.0-py3.10.egg

```

2. 运行容器后在容器中操作以下内容

```bash
# 进行root目录

cd /root

# copy文件到当前目录

cp /usr/local/openvpn_as/lib/python/pyovpn-2.0-py3.10.egg .

```

3. 对从容器中copy出来的文件进行解压

```bash
# 安装相关软件：

apt update && apt install -y unzip zip

# 解压文件并备份

unzip -q pyovpn-2.0-py3.8.egg
cd ./pyovpn/lic/
mv uprop.pyc uprop2.pyc

```

4. 创建用于破解的python文件

```python
# 版本会自动识别，有些版本会存在2048不能正常使用，请修改为1024个会话

from pyovpn.lic import uprop2
old_figure = None

def new_figure(self, licdict):
      ret = old_figure(self, licdict)
      ret['concurrent_connections'] = 2048
      return ret

for x in dir(uprop2):
      if x[:2] == '__':
         continue
      if x == 'UsageProperties':
         exec('old_figure = uprop2.UsageProperties.figure')
         exec('uprop2.UsageProperties.figure = new_figure')
      exec('%s = uprop2.%s' % (x, x))

```

5. 对需要破解的文件进行处理

```bash
# 编译相关的python文件

python3 -O -m compileall uprop.py && mv __pycache__/uprop.*.pyc uprop.pyc

# 回到最开始的目录

cd ../../

# 对编译后的文件进行压缩

zip -rq pyovpn-2.0-py3.8.egg ./pyovpn ./EGG-INFO ./common

# 在宿主机上另起一个shell窗口，将编译后的文件copy到宿主机

mkdir openvpn-as
cd openvpn-as
docker cp d21a057beb84:/root/pyovpn-2.0-py3.10.egg .

```

6. 创建新的Dockerfile

```dockerfile
# Dockerfile

FROM openvpn:2.12.1-ubuntu22
COPY pyovpn-2.0-py3.10.egg /opt/pyovpn-2.0-py3.10.egg
RUN sed -i '/ln -s \/openvpn\/etc/a \cp -rf \/opt\/pyovpn-2.0-py3.10.egg \/usr\/local\/openvpn_as\/lib\/python\/' /docker-entrypoint.sh

```

7. 二次编译官方的docker镜像

```yaml
docker build -t openvpn:2.12.2 .

```

8. 使用新编译的镜像启动，注意查看日志，默认的密码在日志中`Auto-generated pass = "PEIal9eZSz3x". Setting in db...`

```bash
# docker-compose.yml

version: '3.8'

networks:
  app-network:
    external: true

services:
  openvpn-as:
    image: openvpn:2.12.2
    container_name: openvpn-as
    cap_add:
NET_ADMIN
    environment:
TZ=Asia/Dubai
PUID=1000
PGID=1000
    volumes:
./data:/openvpn
    ports:
"10.100.11.254:943:943"
"10.100.11.254:9443:9443"
"10.100.11.254:1194:1194/udp"
    networks:
app-network
    restart: unless-stopped

```

9. 常用密码使用方法

```bash
使用指定密码创建/重置openvpn管理本地帐户：

cd /usr/local/openvpn_as/scripts
./sacli --user "openvpn" --key "prop_superuser" --value "true" UserPropPut
./sacli --user "openvpn" --key "user_auth_type" --value " local" UserPropPut
./sacli --user "openvpn" --new_pass=<PASSWORD> SetLocalPassword
./sacli start

如果帐户需要，请禁用拒绝登录标志并重置 MFA：

./sacli --user "openvpn" --key "prop_deny" --value "false" UserPropPut
./sacli --user "openvpn" --key "prop_google_auth" UserPropDel
./sacli --user "openvpn" --lock 0 GoogleAuthRegen
./sacli start

重置密码锁定策略以防万一它被触发：

./sacli --key "vpn.server.lockout_policy.reset_time" --value "1" ConfigPut
./sacli start
sleep 2
./sacli --key "vpn.server.lockout_policy.reset_time" ConfigDel
./sacli start

尝试使用openvpn和您指定的密码再次登录到 Admin Web UI 。
关于单用户多并发登陆的问题，我在WEB页面打开了多会话，但是没有用，我在官方看到的方案，但是没有成功，以下是官方回复：

配置数据库中每个用户多个会话设置的实际配置参数是“vpn.server.duplicate_cn”。您可以在命令行上以 root 用户身份手动设置它；

/usr/local/openvpn_as/scripts/sacli --key "vpn.server.duplicate_cn" --value "true" ConfigPut
/usr/local/openvpn_as/scripts/sacli start
可以用false关闭，true开启它在。如果你删除它，它会变成默认值，我相信这是真的；

/usr/local/openvpn_as/scripts/sacli --key "vpn.server.duplicate_cn" ConfigDel
/usr/local/openvpn_as/scripts/sacli start

```
