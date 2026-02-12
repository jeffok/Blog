---
title: Mariadb Docker-compose异地集群
date: 2019-09-03 19:35:00
tags: ["容器", "数据库", "Docker", "MariaDB"]
categories: ["DB", "Mysql"]
render_with_liquid: false
permalink: /posts/2019-09-03-Mariadb-Docker-compose异地集群/
---
使用docker-compose运行Mariadb 10.6集群，服务器配置2u2g，对并发，缓存，临时表，慢查询等进行优化

> 服务器ip地址分别为：192.168.8.222，10.100.50.222，10.100.20.2

Docker-compose.yml文件

> 服务器A：192.168.8.222

```yaml
version: '3.8'

services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: "YOUR_PASSWORD"
      GALERA_CLUSTER_BOOTSTRAP: "yes"  # 仅首次启动集群时在这台机器上设置为yes
      GALERA_CLUSTER_ADDRESS: "gcomm://192.168.8.222,10.100.50.222,10.100.20.2"
      GALERA_CLUSTER_NAME: "mariadb_cluster"
      GALERA_NODE_ADDRESS: "192.168.8.222"
      GALERA_NODE_NAME: "mariadb_node01"
    command: --wsrep-new-cluster
    ports:
"3306:3306"    # 客户端连接端口
"4567:4567"    # Galera Cluster复制端口
"4567:4567/udp" # Galera Cluster复制端口 (UDP)
"4568:4568"    # IST端口
"4444:4444"    # SST端口
    volumes:
./custom.cnf:/etc/mysql/mariadb.conf.d/99-my_custom.cnf
./db_data:/var/lib/mysql
./db_logs:/var/log/mysql  # 持久化日志的目录

  redis:
    image: redis:7
    command: ["redis-server", "--appendonly", "yes", "--cluster-enabled", "yes", "--cluster-config-file", "/data/nodes.conf", "--cluster-node-timeout", "5000"]
    ports:
"6379:6379"
    volumes:
./redis.conf:/usr/local/etc/redis/redis.conf
./redis_data:/data

```

> 服务器B：10.100.50.222

```yaml
version: '3.8'
services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: "YOUR_PASSWORD"
      GALERA_CLUSTER_BOOTSTRAP: "no"
      GALERA_CLUSTER_ADDRESS: "gcomm://192.168.8.222,10.100.50.222,10.100.20.2"
      GALERA_CLUSTER_NAME: "mariadb_cluster"
      GALERA_NODE_ADDRESS: "10.100.50.222"
      GALERA_NODE_NAME: "mariadb_node02"
    ports:
"3306:3306"    # 客户端连接端口
"4567:4567"    # Galera Cluster复制端口
"4567:4567/udp" # Galera Cluster复制端口 (UDP)
"4568:4568"    # IST端口
"4444:4444"    # SST端口
    volumes:
./custom.cnf:/etc/mysql/mariadb.conf.d/99-my_custom.cnf
./db_data:/var/lib/mysql
./db_logs:/var/log/mysql  # 持久化日志的目录

  redis:
    image: redis:7
    command: ["redis-server", "--appendonly", "yes", "--cluster-enabled", "yes", "--cluster-config-file", "/data/nodes.conf", "--cluster-node-timeout", "5000"]
    ports:
"6379:6379"
    volumes:
./redis.conf:/usr/local/etc/redis/redis.conf
./redis_data:/data

```

> 服务器C：10.100.20.2

```yaml
version: '3.8'
services:
  mariadb:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: "YOUR_PASSWORD"
      GALERA_CLUSTER_BOOTSTRAP: "no"
      GALERA_CLUSTER_ADDRESS: "gcomm://192.168.8.222,10.100.50.222,10.100.20.2"
      GALERA_CLUSTER_NAME: "mariadb_cluster"
      GALERA_NODE_ADDRESS: "10.100.20.2"
      GALERA_NODE_NAME: "mariadb_node03"
    ports:
"3306:3306"    # 客户端连接端口
"4567:4567"    # Galera Cluster复制端口
"4567:4567/udp" # Galera Cluster复制端口 (UDP)
"4568:4568"    # IST端口
"4444:4444"    # SST端口
    volumes:
./custom.cnf:/etc/mysql/mariadb.conf.d/99-my_custom.cnf
./db_data:/var/lib/mysql
./db_logs:/var/log/mysql  # 持久化日志的目录

  redis:
    image: redis:7
    command: ["redis-server", "--appendonly", "yes", "--cluster-enabled", "yes", "--cluster-config-file", "/data/nodes.conf", "--cluster-node-timeout", "5000"]
    ports:
"6379:6379"
    volumes:
./redis.conf:/usr/local/etc/redis/redis.conf
./redis_data:/data

```

> 注意：
第一次启动集群
首次启动时，在服务器A上，将GALERA_CLUSTER_BOOTSTRAP设置为yes，并使用--wsrep-new-cluster命令启动服务。这意味着首次启动集群时，你可能需要暂时修改docker-compose.yml文件或通过命令行参数来覆盖这个环境变量。
集群启动后，在其他服务器（服务器B和C）上，确保GALERA_CLUSTER_BOOTSTRAP为no，然后启动它们的容器。这些节点会自动加入由服务器A启动的集群。

## custom.cnf 配置文件

```ini
[mysqld]

# 通用设置

character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default_storage_engine=InnoDB
skip-name-resolve

# InnoDB 设置

innodb_file_per_table=1
innodb_buffer_pool_size=512M # 增加缓冲池大小，适用于2GB内存
innodb_log_file_size=64M # 调整日志文件大小
innodb_log_buffer_size=16M # 维持日志缓冲区大小
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_read_io_threads=4 # 维持IO线程数量
innodb_write_io_threads=4 # 维持IO线程数量
innodb_thread_concurrency=0 # 让InnoDB自动决定最优并发数

# 并发处理

max_connections=75 # 调整并发连接数，适中增加
thread_cache_size=8 # 维持线程缓存大小
thread_handling=pool-of-threads
thread_pool_size=2 # 线程池大小，匹配CPU核心数
thread_pool_stall_limit=500

# 表和文件缓存

table_open_cache=1000 # 调整表缓存大小
table_definition_cache=800 # 调整表定义缓存
open_files_limit=2000 # 调整打开文件限制

# 临时表

tmp_table_size=64M # 维持临时表大小
max_heap_table_size=64M # 维持堆表大小

# 二进制日志 - 对于Galera Cluster很重要

binlog_format=ROW
log_bin
expire_logs_days=7 # 调整日志过期天数
max_binlog_size=100M # 维持二进制日志最大大小

# 慢查询日志

slow_query_log=1
slow_query_log_file=/var/log/mysql/mariadb-slow.log
long_query_time=2
log_queries_not_using_indexes=1

# Galera Cluster特定设置

wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://192.168.8.222,10.100.50.222,10.100.20.2"
wsrep_cluster_name="mariadb_cluster"
wsrep_node_address="this_node_ip" # 替换为当前节点的实际IP地址
wsrep_node_name="mariadb_node01" # 根据实际情况进行命名
wsrep_sst_method=rsync

```

redis.conf 配置文件

```bash
# 启用AOF持久化，并设置为每秒fsync

appendonly yes
appendfsync everysec

# 设置最大内存限制，根据您的实际服务器配置调整

maxmemory 256mb
maxmemory-policy allkeys-lru

# 设置密码，替换yourpassword为您的密码

requirepass Wangke0912

# 禁用不必要的命令

rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command SHUTDOWN ""

# 网络设置优化

tcp-backlog 2048
tcp-keepalive 300

# 开启慢查询日志

slowlog-log-slower-than 10000
slowlog-max-len 128

# 其他性能优化

activerehashing yes
hz 10

```
