---
title: Ceph 替换 OSD 步骤
date: 2022-10-18 20:51:59
tags: [ceph]
categories: [技术]
---

# 前言
* [相关博文]()
* [个人博客首页](https://jeffok.com)

---

# 操作步骤

## 1. 关闭平衡
```bash
ceph osd set norecover
ceph osd set nobackfill 
```

## 2. 移除磁盘
```bash
ceph osd purge osd.97 --force
```

## 3. 格式化并加入磁盘
```bash
ceph-deploy disk zap <osd_server_name> /dev/sdac
ceph-deploy osd create <osd_server_name>  --bluestore --data /dev/sdac
```

## 4. 导出 map
```bash
cd /root/ceph-admin
ceph osd getmap > osdmap.bin
```

## 5. 计算 metadata
```bash
osdmaptool --upmap-pool cephfs_metadata osdmap.bin --upmap upmap.txt --upmap-deviation 1 --upmap-max 1000
awk '{print $0" &"}' upmap.txt >upmap2.txt
source upmap2.txt
```

## 6. 计算 data
```bash
osdmaptool --upmap-pool cephfs_data osdmap.bin --upmap upmap.txt --upmap-deviation 1 --upmap-max 10000
awk '{print $0" &"}' upmap.txt >upmap2.txt
source upmap2.txt
```

## 7. 开启平衡
```bash
ceph osd unset norecover   # 平衡
ceph osd unset nobackfill  # 回填
```

---

# 参考资料
* [参考资料1]()
* [参考资料2]()

---

# 交个朋友
* [Github](https://github.com/jeffok)
* [Twitter](https://twitter.com/bytesjeff)
* [Telegram](https://t.me/hello_jeff)
