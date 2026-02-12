---
title: CephL版Config
date: 2020-02-28 11:03:00
tags: ["存储", "Ceph", "RBD"]
categories: ["Ceph"]
render_with_liquid: false
permalink: /posts/2020-02-28-CephL版Config/
---

本文档提供 Ceph Luminous (L版) 版本的完整配置文件示例，包含性能优化和常用配置项。

## Ceph L 版配置文件

`ceph.conf` 配置文件示例：

```ini
## ceph.conf

[global]
fsid = 00bf66fc-dec3-4f55-8e90-eb2fd3c4725e
mon_initial_members = sze0-opsinit-test01, sze0-opsinit-test02, sze0-opsinit-test03
mon_host = 10.225.97.5,10.225.97.6,10.225.97.7
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
public_network = 10.225.97.0/24
cluster_network = 10.225.97.0/24

mon_max_pg_per_osd = 2000

rbd_default_features = 3
rbd_cache = false
rbd_cache_writethrough_until_flush = false
rbd_default_format = 2

# cephx require signatures = False

# cephx sign messages = False

ms_crc_header = False
ms_crc_data = False
ms type = async
perf = True
rocksdb_perf = True

[osd]
objecter inflight ops = 0
osd objectstore = bluestore
osd_min_pg_log_entries = 10
osd_max_pg_log_entries = 10
osd_pg_log_dups_tracked = 10
osd_pg_log_trim_min = 10
osd_pool_default_size = 3
osd_pool_default_min_size = 1
osd_pool_default_pg_num = 1024
osd_pool_default_pgp_num = 1024
osd memory target = 9415205847
osd_max_backfills = 1
osd_recovery_op_priority = 10
osd_max_write_size = 512
osd_client_message_size_cap = 2147483648
osd_deep_scrub_stride = 131072
osd_heartbeat_interval = 6
osd_map_cache_size = 1024
osd_client_op_priority = 63
osd_recovery_max_active = 1
osd_recovery_max_chunk = 131072
osd_recovery_threads = 2
osd_scrub_chunk_min = 5
osd_scrub_chunk_max = 10
osd_scrub_sleep = 0.2
osd_deep_scrub_interval = 1209600.000000
osd_scrub_begin_hour = 0
osd_scrub_end_hour = 24
osd_recovery_sleep = 0.5
osd_enable_op_tracker = true
osd_num_op_tracker_shard = 32
osd_op_threads = 8
osd_disk_thread_ = 1
osd_op_num_shards = 24
osd_op_num_threads_per_shard = 2
osd_op_thread_timeout = 100
osd_op_thread_suicide_timeout = 300
osd_recovery_thread_timeout = 100
osd_recovery_thread_suicide_timeout = 300

bluestore_cache_size = 0
bluestore_cache_autotune = 0
bluestore_csum_type = none
bluestore_cache_kv_max = 200G
bluestore_cache_kv_ratio = 0.2
bluestore_cache_meta_ratio = 0.8
bluestore_cache_size_ssd = 20G
bluestore_cache_size_hdd = 10G
bluestore_extent_map_shard_min_size = 50
bluestore_extent_map_shard_max_size = 200
bluestore_extent_map_shard_target_size = 100
bluestore_rocksdb_options = compression=kNoCompression,max_write_buffer_number=64,\
min_write_buffer_number_to_merge=32,recycle_log_file_num=64,\
compaction_style=kCompactionStyleLevel,write_buffer_size=4MB,\
target_file_size_base=4MB,max_background_compactions=64,\
level0_file_num_compaction_trigger=64,level0_slowdown_writes_trigger=128,\
level0_stop_writes_trigger=256,max_bytes_for_level_base=6GB,\
compaction_threads=32,flusher_threads=8,compaction_readahead_size=2MB

[mon]
mon_allow_pool_delete = true

# mon pg warn max per osd = 800

mon_clock_drift_allowed = 2
mon_osd_allow_primary_affinity = true
mon_osd_down_out_interval = 3600
mon_max_pool_pg_num = 166496
mon_osd_max_split_count = 10000

[client]
rbd_cache = false
rbd_op_threads = 8

# rbd_cache_size = 268435456

rbd_cache_writethrough_until_flush = false

# rbd cache max dirty object = 8

```
