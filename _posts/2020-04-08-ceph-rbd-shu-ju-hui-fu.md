---
title: Ceph RBD 数据恢复
date: 2020-04-08 05:04:00
tags: [ceph]
categories: [技术]
---

# 前言
* [相关博文]()
* [个人博客首页](https://jeffok.com)

---

# 操作步骤

当前只是记录一下，使用该脚本恢复了数百台虚拟机，实际使用过，感谢一起连续加班的小伙伴

```bash
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

set -e
read -p '虚拟机UUID  :' UUID
read -p '磁盘大小G   :' SIZE
mkdir -p data
VMUUID=`echo $UUID | tr 'A-Z' 'a-z'`

# 获取id
rados -p rbd-vms get rbd_id.${VMUUID}_disk rbd_id.txt

# 获取元数据
rados -p rbd-vms ls | grep `cat -v rbd_id.txt | awk -F '@' '{print $4}'` >> rbd_data.txt
cat rbd_data.txt | awk -F '.' '{print $3}' >> index.txt
OLD_HEAD_ID=`cat rbd_data.txt|awk -F '.' '{print $1"."$2}'|head -1`

# 创建空白磁盘
NUM=`cat rbd_data.txt|wc -l`
#SIZE=`echo "${NUM}*4/1024+5"|bc`
#echo $SIZE $NUM
rbd create rbd-vms/${VMUUID}_restore_disk -s ${SIZE}G
NEW_RBD_ID=`rbd info rbd-vms/${VMUUID}_restore_disk | grep block_name_prefix|awk -F ': ' '{print $2}'`
DISK=`rbd info rbd-vms/${VMUUID}_restore_disk`
echo "rbd-vms/${VMUUID}_restore_disk \n $DISK" >> disk_new.txt

# 调整并发 默认200
thread=500
THRE=`echo "$NUM/$thread"|bc`
split -l $THRE index.txt

for f in `ls x*`
do
    for i in `cat $f`
    do
        #count=`ps -ef |grep rados |grep -v "grep" |wc -l`
        count=`ps -ef |grep ceph_object_restroe.sh |grep -v "grep" |wc -l`
        if [ $count -le $thread ];then
            echo " >>>>>>: $i" >> get.log
            rados -p rbd-vms get ${OLD_HEAD_ID}.$i data/$i >> get.log 2>&1
            if [ -f "data/$i" ];then
                sleep 2
                echo " >>>>>>: $i" >> put.log
                rados -p rbd-vms put ${NEW_RBD_ID}.$i data/$i >> put.log 2>&1
            else
                echo "$i is not in data" >> error.log 2>&1
            fi

        else
            sleep 10
            echo " >>>>>>: $i" >> get.log
            rados -p rbd-vms get ${OLD_HEAD_ID}.$i data/$i >> get.log 2>&1
            if [ -f "data/$i" ];then
                sleep 2
                echo " >>>>>>: $i" >> put.log
                rados -p rbd-vms put ${NEW_RBD_ID}.$i data/$i >> put.log 2>&1
            else
                echo "$i is not in data" >> error.log 2>&1
            fi
        fi

    done &
done
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
