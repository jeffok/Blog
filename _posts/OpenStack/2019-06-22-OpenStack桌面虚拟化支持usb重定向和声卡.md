---
title: OpenStack桌面虚拟化支持usb重定向和声卡
date: 2019-06-22 12:52:00
tags: ["云计算", "OpenStack", "Nova"]
categories: ["OpenStack"]
render_with_liquid: false
permalink: /posts/2019-06-22-OpenStack桌面虚拟化支持usb重定向和声卡/
---

本文档介绍 OpenStack桌面虚拟化支持usb重定向和声卡 的相关内容。

```bash
公司测试OpenStack的桌面虚拟化，默认情况下生成的libvirt的xml是不支持USB重定向和声卡，最快捷的方法就是，Hack下源码，硬加进去：

vim /usr/lib/python2.6/site-packages/nova/virt/libvirt/driver.py

    def to_xml(self, context, instance, network_info, disk_info,
               image_meta=None, rescue=None,
               block_device_info=None, write_to_disk=False):
        # We should get image metadata every time for generating xml
        if image_meta is None:
            (image_service, image_id) = glance.get_remote_image_service(
                                            context, instance['image_ref'])
            image_meta = compute_utils.get_image_metadata(
                                context, image_service, image_id, instance)
        # NOTE(danms): Stringifying a NetworkInfo will take a lock. Do
        # this ahead of time so that we don't acquire it while also
        # holding the logging lock.
        network_info_str = str(network_info)
        LOG.debug(_('Start to_xml '
                    'network_info=%(network_info)s '
                    'disk_info=%(disk_info)s '
                    'image_meta=%(image_meta)s rescue=%(rescue)s'
                    'block_device_info=%(block_device_info)s'),
                  {'network_info': network_info_str, 'disk_info': disk_info,
                   'image_meta': image_meta, 'rescue': rescue,
                   'block_device_info': block_device_info},
                  instance=instance)
        conf = self.get_guest_config(instance, network_info, image_meta,
                                     disk_info, rescue, block_device_info)
        pre_xml = conf.to_xml()
        hack_xml = """
<append>
<controller type='usb' index='0' model='ich9-ehci1'/>
<controller type='usb' index='0' model='ich9-uhci1'>
  <master startport='0'/>
</controller>
<controller type='usb' index='0' model='ich9-uhci2'>
  <master startport='2'/>
</controller>
<controller type='usb' index='0' model='ich9-uhci3'>
  <master startport='4'/>
</controller>
<redirdev bus='usb' type='spicevmc'/>
<redirdev bus='usb' type='spicevmc'/>
<redirdev bus='usb' type='spicevmc'/>
<redirdev bus='usb' type='spicevmc'/>
<sound model='ich6'>
  <alias name='sound0'/>
</sound>
</append>
"""
        tar_obj = ''
        libvit_obj = minidom.parseString(pre_xml)
        hack_obj = minidom.parseString(hack_xml)
        for c_lib_obj in libvit_obj.childNodes[0].childNodes:
            if (isinstance(c_lib_obj, minidom.Element) and c_lib_obj.tagName == 'devices'):
                c_lib_obj.childNodes.extend(hack_obj.childNodes[0].childNodes)

        xml = libvit_obj.toxml()
        if write_to_disk:
            instance_dir = libvirt_utils.get_instance_path(instance)
            xml_path = os.path.join(instance_dir, 'libvirt.xml')
            libvirt_utils.write_to_file(xml_path, xml)

        LOG.debug(_('End to_xml xml=%(xml)s'),
                  {'xml': xml}, instance=instance)
        return xml

简单的说，就是让Nova生成libvirt xml的时候，硬编码进去相关的xml标签，好暴力，但是高效好用！

```
