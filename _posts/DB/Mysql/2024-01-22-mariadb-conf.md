---
title: mariadb.conf
date: 2024-01-22 13:17:00
tags: ["MySQL", "数据库", "MariaDB"]
categories: ["DB", "Mysql"]
render_with_liquid: false
permalink: /posts/2024-01-22-mariadb-conf/
---

本文档介绍 mariadb.conf 的相关内容。

```ini
[mysqld]
port = 3306
bind-address = 0.0.0.0

collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

skip-external-locking
key_buffer_size = 64M
max_allowed_packet = 1024M
table_open_cache = 256
sort_buffer_size = 2M
net_buffer_length = 8K
read_buffer_size = 2M
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 16M
thread_cache_size = 32
query_cache_size = 0
tmp_table_size = 64M

# skip-networking

max_connections = 8192
max_connect_errors = 1000
open_files_limit = 65535

server-id = 13683
log-bin = mysql-bin
binlog_format = mixed
expire_logs_days = 90
log_warnings = 2
slow_query_log = 1
slow_query_log_file = /var/log/mariadb/mariadb-slow.log
long_query_time = 1

default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_data_home_dir = /var/lib/mysql
innodb_data_file_path = ibdata1:2G:autoextend
innodb_log_group_home_dir = /var/lib/mysql
innodb_read_io_threads = 16
innodb_write_io_threads = 16
innodb_thread_concurrency = 0
innodb_buffer_pool_size = 16G
innodb_log_file_size = 2G
innodb_log_buffer_size = 64M
innodb_log_files_in_group = 2
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
bulk_insert_buffer_size = 16M
myisam_sort_buffer_size = 16M

[mysqldump]
quick
max_allowed_packet = 512M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 64M
sort_buffer_size = 2M
read_buffer = 4M
write_buffer = 4M

[mysqlhotcopy]
interactive-timeout

```
