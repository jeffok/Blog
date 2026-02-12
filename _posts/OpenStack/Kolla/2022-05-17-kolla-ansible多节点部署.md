---
title: kolla-ansible多节点部署
date: 2022-05-17 19:43:20
tags: ["自动化", "Kolla", "Ansible", "OpenStack"]
categories: ["OpenStack", "Kolla"]
render_with_liquid: false
permalink: /posts/2022-05-17-kolla-ansible多节点部署/
---

# kolla-ansible 多节点部署 OpenStack Rocky 以及与 Ceph Luminous 对接使用

kolla build openstack 镜像时访问公司 git 需要登录 VPN：

```bash
yum -y install openvpn
openvpn --daemon --config /opt/hujh201902200927_vpn.ovpn --auth-user-pass /opt/passwd

```

`passwd` 文件自己创建第一行用户名，第二行密码

## 使用公司 yum 源

```bash
wget http://yum.example.com:9180/repo/Cloud-Example.repo

```

## 添加公司 pip 源加速

```bash
vim /etc/pip.conf

```

```ini
[global]
index-url = https://ops-pypi.example.com/root/ops-pypi/+simple/
[install]
trusted-host = ops-pypi.example.com

```

## 升级内核 4.4

```bash
yum remove -y kernel kernel-tools kernel-tools-libs kernel-devel && \
  yum install -y kernel-lt kernel-lt-tools kernel-lt-tools-libs kernel-lt-devel kernel-lt-headers

rpm -qa | grep kernel
grub2-set-default 0
reboot

```

## 虚机测试环境

3 controller 节点（存储计算融合），双网卡 eth0 做管理网络，eth1（不配置 IP 地址）做 neutron 虚机网络

```yaml
10.224.100.51 controller1   //kolla 和 kolla-ansible 项目部署节点
10.224.100.52 controller2
10.224.100.53 controller3

```

keepalived VIP: `10.224.100.54`

## 1. 系统初始化设置

主机名、`/etc/hosts` 文件、selinux、防火墙，配置部署节点到其他节点互信等：

```bash
hostnamectl set-hostname controller2 --static
yum -y install ntp
systemctl enable ntpd.service && systemctl start ntpd.service && systemctl status ntpd.service

```

## 2. 所有节点安装相关 yum 源及 python 包

```bash
wget -O /etc/yum.repo.d/Cloud-Example.repo http://yum.example.com:9180/repo/Cloud-Example.repo
yum update -y && reboot
yum install -y python-pip
pip install -U pip
yum install -y python-devel libffi-devel vim gcc git openssl-devel libselinux-python

```

## 3. 所有节点安装 docker

### 先用清华的 yum 源安装

```bash
wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
yum -y install docker-ce
docker -v

```

### docker 相关配置

```ini
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF

```

### 修改 docker0 的地址

```yaml
mkdir -p /etc/docker
cat /etc/docker/daemon.json

```

```json
{"bip": "10.35.0.1/24"}

```

```bash
systemctl daemon-reload && systemctl start docker && systemctl enable docker && systemctl status docker
brctl addbr docker0
ip addr add 10.35.0.1/24 dev docker0
ip link set dev docker0 up
ip addr add 172.17.0.1/24 dev docker0

```

## 4. 安装基础包

### 部署节点安装

```yaml
pip install -U ansible==2.7.10
pip install -U tox
pip install -U python-openstackclient  # openstack 客户端工具包（后面安装也可以）

```

所有节点安装：docker python 包，jinja2

```yaml
pip install -U docker==3.7.2
pip install -U Jinja2==2.10.1

```

### 查看确认版本

```ini
pip freeze
urllib3==1.10.2
ansible==2.7.9（部署节点有）
Jinja2==2.10
docker==3.7.2

```

### python 包固定版本

```bash
ansible                          2.7.10
chardet                          3.0.4
docker                           3.7.2
Jinja2                           2.10.1
kolla                            7.0.3.dev11 /opt/kolla
kolla-ansible                    7.1.1.dev20 /opt/kolla-ansible
PyYAML                           5.1
requests                         2.21.0
urllib3                          1.24.3

```

## 5. 在部署节点上安装 kolla 和 kolla-ansible

kolla 项目用来 build OpenStack 相关镜像，kolla-ansible 用来部署 OpenStack。

### a. 安装 kolla

#### 源码安装

```bash
cd /opt/

# 注意：不要在文档里写入真实账号/密码，建议使用 SSH key 或者临时 Token + 环境变量方式认证

git clone https://gitlab.example.com/openstack/rocky/kolla.git -b stable/rocky
cd /opt/kolla
pip install -r requirements.txt -r test-requirements.txt -e .  # 安装依赖环境

```

生成配置文件：

```text
tox -egenconfig

```

注意：配置修改 kolla 项目，使用自己的 yum 源，和定义相关软件包等，参考 `kolla改动_20190509.txt`

```text
mkdir /etc/kolla/
cp etc/kolla/kolla-build.conf /etc/kolla/

```

#### 设置 build 镜像的细则

```bash
vim /etc/kolla/kolla-build.conf

```

```ini
[DEFAULT]
base = centos
namespace = kolla
cache = true
profile = main
push = false
retries = 3
install_type = source
threads = 8
tag = rocky
timeout = 120
rpm_setup_config = Cloud-Example.repo

[profiles]
main = chrony,cron,fluentd,kolla-toolbox,glance,haproxy,horizon,keepalived,keystone,mariadb,memcached,neutron,nova,rabbitmq,cinder

[keystone-base]
type = git
location = https://example.com/openstack/rocky/keystone.git
reference = stable/rocky

[glance-base]
type = git
location = https://gitlab.example.com/openstack/rocky/glance.git
reference = stable/rocky

[nova-base]
type = git
location = https://gitlab.example.com/openstack/rocky/nova.git
reference = stable/rocky

[neutron-base]
type = git
location = https://gitlab.example.com/openstack/rocky/neutron.git
reference = stable/rocky

[horizon-base]
type = git
location = https://gitlab.example.com/openstack/rocky/horizon.git
reference = stable/rocky

[cinder-base]
type = git
location = https://gitlab.example.com/openstack/rocky/cinder.git
reference = stable/rocky

```

在 build openstack 镜像之前，我们要设置好 centos7.5 base 的镜像：

### 在部署节点上，启动 docker 私有仓库

```bash
mkdir -p /opt/registry
docker run -d -v /opt/registry:/var/lib/registry -p 10.224.100.33:4000:5000 --restart=always --name registry registry:2.3

```

### (1) 先拉取 centos7.5 的镜像

```dockerfile
docker pull centos:centos7.5.1804
cd /root
vim Dockerfile

```

```dockerfile
FROM centos:centos7.5.1804
RUN rm -f /etc/yum.repos.d/*

```

```yaml
docker build ./ -t centos7.5-1804:rocky

```

### 修改 docker 配置

```bash
cat /etc/systemd/system/docker.service.d/kolla.conf

```

```ini
[Service]
MountFlags=shared
ExecStart=
ExecStart=/usr/bin/dockerd --insecure-registry 10.224.100.33:4000

```

```bash
systemctl daemon-reload && systemctl restart docker

```

### (2) 推送到私有仓库

```yaml
docker tag image_uuid 10.224.100.33:4000/kolla/centos7.5-1804:rocky
docker push 10.224.100.33:4000/kolla/centos7.5-1804:rocky

```

### 执行创建镜像命令

```bash
cd /opt/kolla/tools
python build.py --base-tag rocky --base-image 10.224.100.33:4000/kolla/centos7.5-1804 --profile main

```

### 本次制作的 OpenStack 项目相关镜像

```bash
chrony,cron,kolla-toolbox,fluentd,glance,haproxy,horizon,keepalived,keystone,mariadb,memcached,neutron,nova,rabbitmq,cinder

```

OpenStack docker 镜像 build 方法：
https://github.com/openstack/kolla/blob/stable/rocky/doc/source/admin/image-building.rst

## 6. build 好的镜像，打 tag，push 到私有 registry 仓库

### a. 把 build 完的 OpenStack 相关镜像打 tag，push 到镜像仓库

例如 nova-compute 容器镜像：

```yaml
docker tag <images_uuid> 10.224.100.51:4000/kolla/centos-source-nova-compute:rocky
docker push 10.224.100.51:4000/kolla/centos-source-nova-compute:rocky

```

### b. 所有节点配置使用 registry 仓库

```bash
cat /etc/systemd/system/docker.service.d/kolla.conf

```

```ini
[Service]
MountFlags=shared
ExecStart=
ExecStart=/usr/bin/dockerd --insecure-registry 10.224.100.51:4000

```

```bash
systemctl daemon-reload && systemctl restart docker && systemctl status docker

```

```bash
curl -XGET http://10.224.100.100:4000/v2/kolla/centos-source-kolla-toolbox/tags/list

```

### 所有节点都验证一下能否正常访问私有仓库

```bash
curl http://10.224.100.51:4000/v2/_catalog

```

```json
{"repositories":["centos","kolla/centos-source-base","kolla/centos-source-chrony","kolla/centos-source-cinder-api","kolla/centos-source-cinder-backup","kolla/centos-source-cinder-scheduler","kolla/centos-source-cinder-volume","kolla/centos-source-cron","kolla/centos-source-fluentd","kolla/centos-source-glance-api","kolla/centos-source-glance-base","kolla/centos-source-glance-registry","kolla/centos-source-haproxy","kolla/centos-source-horizon","kolla/centos-source-keepalived","kolla/centos-source-keystone","kolla/centos-source-keystone-fernet","kolla/centos-source-keystone-ssh","kolla/centos-source-kolla-toolbox","kolla/centos-source-mariadb","kolla/centos-source-memcached","kolla/centos-source-neutron-base","kolla/centos-source-neutron-dhcp-agent","kolla/centos-source-neutron-l3-agent","kolla/centos-source-neutron-lbaas-agent","kolla/centos-source-neutron-linuxbridge-agent","kolla/centos-source-neutron-metadata-agent","kolla/centos-source-neutron-openvswitch-agent","kolla/centos-source-neutron-server","kolla/centos-source-nova-api","kolla/centos-source-nova-base","kolla/centos-source-nova-compute","kolla/centos-source-nova-compute-ironic","kolla/centos-source-nova-conductor","kolla/centos-source-nova-consoleauth","kolla/centos-source-nova-libvirt","kolla/centos-source-nova-novncproxy","kolla/centos-source-nova-placement-api","kolla/centos-source-nova-scheduler","kolla/centos-source-nova-ssh","kolla/centos-source-openstack-base","kolla/centos-source-openvswitch-base","kolla/centos-source-openvswitch-db-server","kolla/centos-source-openvswitch-vswitchd","kolla/centos-source-rabbitmq"]}

```

## 7. 安装 Kolla-ansible

### 源码安装

```yaml
cd /opt
git clone https://gitlab.example.com/openstack/rocky/kolla-ansible.git -b stable/rocky

cd /opt/kolla-ansible
pip install -r requirements.txt -r test-requirements.txt -e .  # 安装相关依赖

```

### 拷贝相关配置文件

```yaml
cp etc/kolla/globals.yml /etc/kolla/       # globals.yml kolla-ansible全局配置文件
cp etc/kolla/passwords.yml /etc/kolla/     # passwords.yml openstack相关服务的密码设置文件
cp ansible/inventory/multinode /etc/kolla/ # kolla-ansible 多节点部署的ansible的hosts清单模板

```

编辑 `passwords.yml`：设定 OpenStack 服务的各种密码，这里仅设定管理员的登陆密码。

```bash
vim /etc/kolla/passwords.yml

```

```text
keystone_admin_password: admin

```

执行 `kolla-genpwd` 自动生成密码来填充 `passwords.yml`

## 8. kolla-ansible 部署前准备

### a. 修改 `/etc/kolla/globals.yml`

设置 kolla-ansible 部署的全局细则：

```yaml
kolla_base_distro: "centos"
kolla_install_type: "source"            # 使用源码方式
openstack_release: "rocky"             # 这里是镜像的tag
kolla_internal_vip_address: "10.224.100.54"  # keepalived的vip地址
docker_registry: "10.224.100.51:4000"         # 指定私有的镜像仓库
docker_namespace: "kolla"                     # 打tag时使用的docker的namespace
network_interface: "eth0"                   # 部署管理地址的网卡接口，vip所在的网卡
neutron_external_interface: "eth1"       # neutron的虚机网络网卡

# neutron_external_interface: "eth1,eth2"   # 假如有多个，用逗号隔开

neutron_plugin_agent: "linuxbridge"        # 设置使用linuxbridge,kolla默认使用的是openvswitch
enable_openvswitch: "{{ neutron_plugin_agent != 'linuxbridge' }}"
keepalived_virtual_router_id: "66"         # 设置keepalived的id，注意不能与同个局域网内的keepalived的id一样
enable_cinder: "yes"                      # 把cinder打开，默认cinder不部署
enable_cinder_backup: "yes"
enable_haproxy: "yes"                 # haproxy默认是使用的，all-in-one单节点要关掉
enable_heat: "no"                      # 关掉OpenStack heat插件

# ... (其他相关定制)

```

### b. 修改多节点部署的 ansible 的 hosts 清单

其他根据实际情况修改：

```bash
vim /etc/kolla/multinode

```

```ini
[control]
controller[1:3]

[network]
controller[1:3]

[inner-compute]

[external-compute]
controller[1:3]

[monitoring]

# monitoring01

[storage]              # 会在storage节点启动cinder_backup和cinder_volume容器
controller[1:3]

# storage01

# ...

```

## 9. 使用 kolla-ansible 进行部署

```yaml
cd /opt/kolla-ansible/tools

```

### a. 执行 bootstrap-servers

处理 bootstrap servers 所需要的依赖：

```yaml
./kolla-ansible -i /etc/kolla/multinode bootstrap-servers

```

### b. 进行部署前的 precheck

检查环境是否有报错（主要是网络问题和软件包版本等）：

```yaml
./kolla-ansible -i /etc/kolla/multinode prechecks

```

### c. prechecks 过了之后执行部署

```yaml
./kolla-ansible -i /etc/kolla/multinode deploy       # -t neutron 指定容器
./kolla-ansible -i /etc/kolla/multinode post-deploy  # 生成admin的认证环境文件/etc/kolla/admin-openrc.sh

```

其他 kolla-ansible 可能需要用到的选项：

```bash
# ./kolla-ansible -i /etc/kolla/multinode reconfigure  # 当配置改动时，kolla刷配置重启相关容器

# ./kolla-ansible -i /etc/kolla/multinode destroy --yes-i-really-really-mean-it  # 需要重新部署的时候，摧毁OpenStack集群

```

### 部署完成后查看容器的执行状态

```bash
docker ps

```

### d. OpenStack 初始化设置（可选）

```yaml
source /etc/kolla/admin-openrc.sh
执行init脚本：/root/kolla-ansible/tools/init-runonce

```

部署完成之后使用 VIP 登录 OpenStack 验证：

## 10. 部署 Ceph Luminous，对接 OpenStack

脚本要根据实际情况修改：

```bash
cat /root/ceph_kolla.sh

```

```bash
#!/bin/bash

# ceph对接kolla-ansible部署的OpenStack环境脚本,只需改动ceph pool的pg_num的数量：

function rm_osd_pool() {
	ceph osd pool rm $1 $1 --yes-i-really-really-mean-it
}

# 按实际情况修改pool的pg_num

function create_osd_pool() {
	ceph osd pool stats images > /dev/null 2>&1
	if [[ "$?" != "0" ]]; then
    	ceph osd pool create $1 128
	else
    	rm_osd_pool $1
		ceph osd pool create $1 128
	fi
}

function make_dir()
{
    if [ ! -f $1 ]; then
        mkdir -p $1
    fi
}

create_osd_pool images
create_osd_pool vms
create_osd_pool backups
create_osd_pool volumes

ceph auth del client.nova
ceph auth del client.cinder
ceph auth del client.glance
ceph auth del client.cinder-backup

ceph auth get-or-create client.cinder mon 'allow *' osd 'allow *' mds 'allow *'
ceph auth get-or-create client.glance mon 'allow *' osd 'allow *' mds 'allow *'
ceph auth get-or-create client.cinder-backup mon 'allow *' osd 'allow *' mds 'allow *'
ceph auth get-or-create client.nova  mds 'allow *' mon 'allow *' osd 'allow *'

make_dir "/etc/kolla/config/glance/"
ceph auth get-or-create client.glance > /etc/kolla/config/glance/ceph.client.glance.keyring
make_dir "/etc/kolla/config/cinder/cinder-backup/"
ceph auth get-or-create client.cinder > /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring
make_dir "/etc/kolla/config/cinder/cinder-volume/"
ceph auth get-or-create client.cinder > /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring

make_dir "/etc/kolla/config/cinder/cinder-backup/"
ceph auth get-or-create client.cinder-backup > /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring

make_dir "/etc/kolla/config/nova/"
ceph auth get-or-create client.nova > /etc/kolla/config/nova/ceph.client.nova.keyring

make_dir "/etc/kolla/config/nova/"
ceph auth get-or-create client.cinder > /etc/kolla/config/nova/ceph.client.cinder.keyring

cp -f /etc/ceph/ceph.conf /etc/kolla/config/nova
cp -f /etc/ceph/ceph.conf /etc/kolla/config/glance
cp -f /etc/ceph/ceph.conf /etc/kolla/config/cinder

cat << EOF > /etc/kolla/config/glance/glance-api.conf
[DEFAULT]
show_multiple_locations = True
show_image_direct_url = True

[glance_store]
stores = rbd
default_store = rbd
rbd_store_pool = images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
EOF

cat << EOF > /etc/kolla/config/cinder/cinder-volume.conf
[DEFAULT]
enabled_backends=rbd-1

[rbd-1]
rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=cinder
backend_host=rbd:volumes
rbd_pool=volumes
volume_backend_name=rbd-1
volume_driver=cinder.volume.drivers.rbd.RBDDriver
rbd_secret_uuid = {{ cinder_rbd_secret_uuid }}
EOF

cat << EOF > /etc/kolla/config/cinder/cinder-backup.conf
[DEFAULT]
backup_ceph_conf=/etc/ceph/ceph.conf
backup_ceph_user=cinder
backup_ceph_chunk_size = 134217728
backup_ceph_pool=backups
backup_driver = cinder.backup.drivers.ceph
backup_ceph_stripe_unit = 0
backup_ceph_stripe_count = 0
restore_discard_excess_bytes = true
EOF

cat << EOF > /etc/kolla/config/nova/nova-compute.conf
[libvirt]

# virt_type=qemu

# cpu_mode=none

# cpu_model=kvm64

images_rbd_pool=vms
images_type=rbd
images_rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=nova
EOF

sed_kolla_globals(){
    local key_word=$1
    local val=$2
    local globals_yml=${3:-/etc/kolla/globals.yml}
    sed -i "s|^#*${key_word}:.*|${key_word}: \"${val}\"|g" $globals_yml
}

sed_kolla_globals "cinder_backend_ceph" "yes"
sed_kolla_globals "cinder_volume_group" "cinder-volumes"
sed_kolla_globals "glance_backend_file" "no"
sed_kolla_globals "glance_backend_ceph" "yes"
sed_kolla_globals "nova_backend_ceph" "yes"

```

修改完 `globals.yml` 之后，执行 `kolla-ansible reconfigure` 使 OpenStack 相关服务配置生效：

对接完 ceph 需要 reconfigure：

```yaml
cd /opt/kolla-ansible/tools/
./kolla-ansible -i /etc/kolla/multinode reconfigure

```

报错：python 包 urllib3 有问题：

```text
ImportError: No module named 'requests.packages.urllib3'

```

### 解决

```bash
pip uninstall urllib3  # 1.24.1版本问题
yum -y install python-urllib3  # 安装1.10.2版本

```

### 把原来的磁盘清理掉，创建 vg

```sql
dd if=/dev/urandom of=/dev/sdd bs=512 count=64

pvcreate /dev/sdb
vgcreate lvm-sas /dev/sdb

```

```sql
openstack server example-resize --flavor 5dd091ee-bcd9-46d4-8e5a-5765699512f6 15c7d646-27ca-42aa-aaeb-a31e6be96ae1

openstack volume create --type sas --size 3 --availability-zone nova:bjdz-cloud-opsnode-A0107-9-1309.example.com@sas sas3

nova boot bjdz-mysql-openstack04 --flavor 29dc9b74-a25c-45fb-b789-23bb271e3e8d --nic net-id=0bfd529c-40bc-475c-be38-133f2e6c7f4e --availability-zone bjdz-az-dmz:bjdz-cloud-opsnode-A0107-8-1308.example.com --block-device id=6cbd4043-ce54-422a-9ce1-56657e1888a8,source=image,dest=volume,device=vda,size=185,bootindex=0,shutdown=remove,volume_type=ssd

nova boot bjdz-mysql-openstack05 --flavor 29dc9b74-a25c-45fb-b789-23bb271e3e8d --nic net-id=0bfd529c-40bc-475c-be38-133f2e6c7f4e --availability-zone bjdz-az-dmz:bjdz-cloud-opsnode-A0107-9-1309.example.com --block-device id=6cbd4043-ce54-422a-9ce1-56657e1888a8,source=image,dest=volume,device=vda,size=185,bootindex=0,shutdown=remove,volume_type=ssd

```

### 在 ceph 机器上操作

```sql
ceph osd pool create glance 1024
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rdb_children, allow rwx pool=images' -o /etc/ceph/ceph.client.glance.keyring

mkdir -p /etc/kolla/config/glance/

# 把认证文件和ceph.conf 拷贝到/etc/kolla/config/glance/下

```

```ini
cat << EOF > /etc/kolla/config/glance/glance-api.conf
[DEFAULT]
show_multiple_locations = True
show_image_direct_url = True

[glance_store]
stores = rbd
default_store = rbd
rbd_store_pool = rbd-images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
EOF

```

### 修改 global.yml 里面的配置

```bash
glance_backend_file: "no"
glance_backend_ceph: "yes"

```

```ini
[DEFAULT]
enabled_backends = sas,ssd

[sas]
volume_group = lvm-sas
volume_driver = cinder.volume.drivers.lvm.LVMISCSIDriver
volume_backend_name = SAS
volume_clear_size = 5

[SSD]
volume_group = lvm-ssd
volume_driver = cinder.volume.drivers.lvm.LVMISCSIDriver
volume_backend_name = SSD
volume_clear_size = 5

```

```bash
# source /etc/kolla/admin-openrc.sh

# cinder type-create SATA

# cinder type-create SSD

# cinder type-list

```

```yaml
+ --------------------------------------+------+-------------+-----------+
| ID                                   | Name | Description | Is_Public |

+ --------------------------------------+------+-------------+-----------+
| 8c1079e5-90a3-4f6d-bdb7-2f25b70bc2c8 | SSD  |             | True      |
| a605c569-1e88-486d-bd8e-7aba43ce1ef2 | SAS |             | True      |

+ --------------------------------------+------+-------------+-----------+

```

设置卷类型的 key 键值：

```ini
cinder type-key SSD set volume_backend_name=ssd
cinder type-key SAS set volume_backend_name=sas
cinder extra-specs-list

```

```yaml
+ --------------------------------------+------+--------------------------------+
| ID                                   | Name | extra_specs                    |

+ --------------------------------------+------+--------------------------------+
| 63ccc62c-3df8-41c7-8256-5be492b1f1c1 | SSD  | {'volume_backend_name': 'ssd'} |
| 7d561912-557d-475f-9811-0a21591c7a8e | SAS  | {'volume_backend_name': 'sas'} |

+ --------------------------------------+------+--------------------------------+

```

在 kolla 中配置 cinder ceph 多后端:
https://www.lijiawang.org/posts/%E5%9C%A8kolla%E4%B8%AD%E9%85%8D%E7%BD%AEcinder%20ceph%E5%A4%9A%E5%90%8E%E7%AB%AF.html#more

## 加密解密 ssl

http://blog.sina.com.cn/s/blog_44ee37cd01016r1h.html

## 虚机创建

http://blog.itpub.net/18796236/viewspace-1840119/

```sql
openstack server set uuid --state active && openstack server uuid reboot --hard

```

## 常用指令

```sql
# ./perccli64 /c0/eall/sall show                    查看物理硬盘信息列表

# ./perccli64 /c0/vall                              查看虚拟磁盘信息列表，即阵列信息

# ./perccli64 /c0 show preservedCache               查看虚拟磁盘丢失信息

# ./perccli64 /c0/fall show all                     查看脱机硬盘信息

# ./perccli64 /c0/v11 delete preservedcache         清除控制器0上的虚拟磁盘11的缓存信息

# ./perccli64 /c0/fall delete                      清除外来硬盘配置信息

# ./perccli64 /c0/fall import [preview ]            导入外来硬盘配置

# ./perccli64 /c0 add vd r0 drives=32:10 wb ra                   编号为32:10的硬盘做raid0

# ./perccli64 /c0 add vd r5 size=all drives=32:01,32:02,32:03    对应编号3块硬盘做raid5

# ./perccli64 /c0 add vd r1 size=all drives=32:01,32:02          对应编号2块硬盘做raid1

```
