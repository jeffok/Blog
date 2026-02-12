---
title: mysql配置文件my.cnf
date: 2024-04-14 12:40:00
tags: ["MySQL", "数据库"]
categories: ["DB", "Mysql"]
render_with_liquid: false
permalink: /posts/2024-04-14-mysql配置文件my-cnf/
---

## > 说明

> 几个值要改改， bind_address=ip 、server-id=ip后两位、innodb_read_io_threads=cpu核数、innodb_write_io_threads=cpu核数，innodb_buffer_pool_size=内存的一半

```ini
[mysql]
no-auto-rehash
safe-updates

[mysqldump]
quick
max_allowed_packet = 1024M

[mysqld]
plugin-load-add = validate_password.so
validate-password = YOUR_PASSWORD
character-set-client-handshake   = FALSE
character-set-server             = utf8mb4
init_connect                     = 'SET NAMES utf8mb4'

# init-file                        = /usr/local/mysql/init-file.sql

skip-name-resolve
query_cache_type                = OFF
query_cache_size                = 0
max_prepared_stmt_count         = 16382
max_connections                 = 4000
max_connect_errors              = 1024
performance_schema              = off
datadir                         = /usr/local/mysql/data
socket                          = /tmp/mysql.sock
innodb_fast_shutdown            = 1
interactive_timeout             = 1800
wait_timeout                    = 1800
max_heap_table_size             = 64M
tmp_table_size                  = 64M
user                            = mysql
explicit_defaults_for_timestamp = true
innodb_autoinc_lock_mode        = 2
log_bin_trust_function_creators = 1
log_timestamps                  = system
read_buffer_size                = 2M
sort_buffer_size                = 2M
join_buffer_size                = 64M
log-error                       = mysql_run.err
pid-file                        = mysql-pid.pid
thread_stack                    = 512k
sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'
bind_address                    = 0.0.0.0

# read_only                      = on

# replication,binlog

server-id                       = 16103
binlog_format                   = row
innodb_support_xa               = 1
sync_binlog                     = 1
log-bin                         = mysql-bin
relay-log-info-repository       = table
relay_log_recovery              = 1
relay-log                       = relay-bin
master-info-repository          = table
expire-logs-days                = 7
max_allowed_packet              = 1024M
slave_parallel_type             = LOGICAL_CLOCK
slave_parallel_workers          = 8
gtid_mode                       = on
enforce-gtid-consistency        = on
log-slave-updates

# innodb

innodb_data_file_path           = ibdata1:2G:autoextend
innodb_read_io_threads          = 4
innodb_write_io_threads         = 4
innodb_buffer_pool_size         = 4GB
innodb-file-per-table           = 1
innodb_flush_log_at_trx_commit  = 1
innodb_log_file_size            = 2G
innodb_log_files_in_group       = 2
innodb_buffer_pool_instances    = 8
innodb_purge_threads            = 8
innodb_io_capacity              = 200
innodb_io_capacity_max          = 400
innodb_file_format              = barracuda
innodb_strict_mode              = 1
innodb_flush_method             = O_DIRECT

# thread pool

thread_handling                 = pool-of-threads
thread_pool_max_threads         = 100000
thread_pool_oversubscribe       = 10

# slowlog

slow-query-log                  = 1
slow-query-log-file             = /usr/local/mysql/data/mysql-slow.log
long_query_time                 = 1

# undo log

innodb_max_undo_log_size        = 5G
innodb_undo_log_truncate        = ON
innodb_undo_logs                = 128
innodb_undo_tablespaces         = 4
innodb_purge_rseg_truncate_frequency = 128
innodb_undo_directory           = /usr/local/mysql/data

[mysqld_safe]
basedir                         = /usr/local/mysql
datadir                         = /usr/local/mysql/data
port                            = 3306

```
