---
title: OpenStack常见问题
date: 2023-03-09 18:58:00
tags: ["Cinder", "云计算", "OpenStack"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2023-03-09-OpenStack常见问题/
---
Maximum number of ports exceeded  最大ports限制

```sql
查看
neutron quota-show
nova absolute-limits
openstack quota show

openstack quota set --ports 50000 <project/class>
openstack quota set --networks 50 jgcloud_bjdz

```

LDAP 进程

```bash
systemctl restart nslcd.service

```

删除Libvirt的default默认网卡信息

```bash
virsh net-destroy default && virsh net-undefine default

```

开启网卡多队列

```ini
hw_qemu_guest_agent='yes'   # agent
hw_vif_multiqueue_enabled='true'
openstack image set 0f3b6603-1d98-4d28-90cb-5cf5fe95d271 --property hw_qemu_guest_agent=yes --property hw_vif_multiqueue_enabled=true

-property hw_vif_multiqueue_enabled=true   多队列

```

过滤显示

```sql
openstack server show 24a4039f-f92a-4fd1-abc4-15983d0165fb |grep -E -w " OS-EXT-SRV-ATTR:host| addresses| flavor| name| id" |awk '{print $4}' |sed -e 's/.example.com//g' -e 's/proint=//g' |sed -e '$!N;s/\n/\ | /g' -e '$!N;s/\n/\ | /g' -e '$!N;s/\n/\ | /g' -e '$!N;s/\n/\ | /g' |awk -F '|' '{print "|| " $5 " | " $2 " | " $3 " | " $4 " | " $1 " ||"}'

||  bjdz-sys-zbxsrv01 |  172.19.33.12;  |  8u16g500GB  |  48d82e76-211d-48ff-b40c-5d228e1b2444  | bjdz_cloud_node008_a0902-09_3224  ||

```

设置cpu内核数量 win系统

```ini
openstack flavor set <NAME> --property hw:cpu_sockets=2 --property hw:cpu_cores=4

```

设置qxl显卡

```ini
openstack image set IMG-UUID --property hw_video_model=qxl

```

添加可用域

```sql
openstack aggregate add host lvm bjdz_cloud_node087_a0910-08_4033.example.com
openstack aggregate remove host lvm bjdz_cloud_node083_A0910-04_4029.example.com

openstack aggregate create bjdz_az1_vlan128_ceph --zone bjdz_az1_vlan128

```

Mysql 连接过大

```bash
检查Mysql最大连接数
show variables like '%connect%';

max_connections  默认为214

如果修改了还是不行，修改启动文件

vim /usr/lib/systemd/system/mariadb.service
增加：
[Service]
...
LimitNOFILE=65535
LimitNPROC=65535
...

systemctl daemon-reload
systemctl restart mariadb

set GLOBAL max_connections=1000  临时设置

```

Cinder 删除lvm服务down

```bash
cinder-manage service remove cinder-volume  2c510cg@lvm

```

Cinder僵尸卷删除方法

```sql
删除数据库中的内容：
cinder list edf2160e-8812-4a3e-986f-bdcd88ea0c60   #cinder 卷的UUID
查找：
select id,status,display_name from volumes where id = 'edf2160e-8812-4a3e-986f-bdcd88ea0c60';
删除：
delete form volumes where id ='059321e9-3b9a-4508-86fa-d7a8531e4c27';
设置为错误：
update volumes set deleted=1 where id ='d267b2d9-24c5-4966-8f85-531188d4d5fb';

```

```bash
1、通过lvdisplay |grep查询cinder对应的卷地址
lvdisplay | grep "3a615ad5-5880-4b68-b1af-f9241ecd9287"

2、通过lsof | grep查询占用cinder卷的端口
lsof| grep "3a615ad5-5880-4b68-b1af-f9241ecd9287"

3、查看是否被打开
dmsetup info -c /dev/cinder-volumes/volume-3a615ad5-5880-4b68-b1af-f9241ecd9287
可以看到open为4说明它被打开了，所以remove不掉。

4、查看是谁打开
fuser -m /dev/cinder-volumes/volume-3a615ad5-5880-4b68-b1af-f9241ecd9287

5、把占用设备的进程杀掉
kill -9  58638

7、重新执行第3和4步，验证是否还有进程占用

8、通过lvremove删除相应的卷
lvremove /dev/cinder-volumes/volume-3a615ad5-5880-4b68-b1af-f9241ecd9287

```

创建虚拟机卡在Starting up ....

```ini
修改nova配置中将cpu模式改为
cpu_mode = none

```

cpu、内存和硬盘资源超配

```bash
它们默认的超配比为：
• CPU: CONF.cpu_allocation_ratio = 16
• RAM: CONF.ram_allocation_ratio = 1.5
• DISK: CONF.disk_allocation_ratio = 1.0
在生产环境中的利用率建议cpu:vcpu 1:1.5 mem 1:1 disk 1:1

```

开机自动启动虚拟机

```ini
修改 /etc/nova.conf，添加两个选项
start_guests_on_host_boot = True
resume_guests_state_on_host_boot =True

注意的是，如果使用了nova-volume，则自动启动还是有问题的。这时，需要自己写脚本，进行启动。
这两个选项在文档中没有说明，大家可以参见代码：

nova/compute/manager.py:
if ((expect_running and FLAGS.resume_guests_state_on_host_boot) or
FLAGS.start_guests_on_host_boot):
LOG.info(_(‘Rebooting instance after nova-compute restart.’),
locals(), instance=instance)
self.reboot_instance(context, instance[‘uuid’])
elif drv_state == power_state.RUNNING:

# Hyper-V and VMWareAPI drivers will raise an exception

try:
net_info = self._get_instance_nw_info(context, instance)
self.driver.ensure_filtering_rules_for_instance(instance,
self._legacy_nw_info(net_info))
except NotImplementedError:
LOG.warning(_(‘Hypervisor driver does not support ‘
‘firewall rules’))

```

openstack 计算节点 virsh console 无法 登陆问题

```bash
关闭虚拟机
virsh destroy instance-000007a2
导出xml
virsh dumpxml instance-000007a2 > test.xml
修改xml
vim test.xml
把
<serial type='file'>
  <source path='/var/lib/nova/instances/1d9fa13c-ff0b-4afd-b3dc-e93b66f19a74/console.log'/>
  <target port='0'/>
  <alias name='serial0'/>
</serial>
<console type='file'>
  <source path='/var/lib/nova/instances/1d9fa13c-ff0b-4afd-b3dc-e93b66f19a74/console.log'/>
  <target type='serial' port='0'/>
  <alias name='serial0'/>
</console>
修改为:
<serial type='pty'>
  <target port='0'/>
</serial>
<console type='pty'>
  <target type='serial' port='0'/>
</console>
从xml文件定义虚拟机
virsh define test.xml
启动虚拟机
virsh start instance-000007a2
登陆虚拟机
virsh console instance-000007a2

```

Openstack Pike Dashboard不能正常访问，出现以下错误的解决方法

```bash
# 错误日志 httpd

[Fri Dec 08 11:32:48.251386 2017] [suexec:notice] [pid 79126] AH01232: suEXEC mechanism enabled (wrapper: /usr/sbin/suexec)
[Fri Dec 08 11:32:48.266330 2017] [auth_digest:notice] [pid 79126] AH01757: generating secret for digest authentication ...
[Fri Dec 08 11:32:48.267016 2017] [lbmethod_heartbeat:notice] [pid 79126] AH02282: No slotmem from mod_heartmonitor
[Fri Dec 08 11:32:48.277801 2017] [mpm_prefork:notice] [pid 79126] AH00163: Apache/2.4.6 (CentOS) mod_wsgi/3.4 Python/2.7.5 configured -- resuming normal operations
[Fri Dec 08 11:32:48.277830 2017] [core:notice] [pid 79126] AH00094: Command line: '/usr/sbin/httpd -D FOREGROUND'
[Fri Dec 08 11:32:55.489711 2017] [autoindex:error] [pid 79144] [client 192.168.20.67:6612] AH01276: Cannot serve directory /var/www/html/: No matching DirectoryIndex (index.html) found, and server-generated directory index forbidden by Options directive
[Fri Dec 08 11:37:59.339107 2017] [core:error] [pid 79142] [client 192.168.20.67:6611] End of script output before headers: django.wsgi

# 解决方法

vim /etc/httpd/conf.d/openstack-dashboard.conf

-----------------------------------
WSGIDaemonProcess dashboard
WSGIProcessGroup dashboard
WSGISocketPrefix run/wsgi
WSGIApplicationGroup %{GLOBAL}   增加此行内容，这样就可以正常访问了

WSGIScriptAlias /dashboard /usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi
Alias /dashboard/static /usr/share/openstack-dashboard/static

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Options All
  AllowOverride All
  Require all granted
</Directory>

<Directory /usr/share/openstack-dashboard/static>
  Options All
  AllowOverride All
  Require all granted
</Directory>

-------------------------------------

```
