#
# Cookbook Name:: mysql
# Attributes:: server
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['mysql']['bind_address']               = attribute?('cloud') ? cloud['local_ipv4'] : ipaddress
default['mysql']['data_dir']                   = "/var/lib/mysql"

case default["platform"]
when "centos", "redhat", "fedora", "suse"
  set['mysql']['conf_dir']                    = '/etc'
  set['mysql']['socket']                      = "/var/lib/mysql/mysql.sock"
  set['mysql']['pid_file']                    = "/var/run/mysqld/mysqld.pid"
  set['mysql']['old_passwords']               = 1
else
  set['mysql']['conf_dir']                    = '/etc/mysql'
  set['mysql']['socket']                      = "/var/run/mysqld/mysqld.sock"
  set['mysql']['pid_file']                    = "/var/run/mysqld/mysqld.pid"
  set['mysql']['old_passwords']               = 0
end

if attribute?('ec2')
  default['mysql']['ec2_path']    = "/mnt/mysql"
  default['mysql']['ebs_vol_dev'] = "/dev/sdi"
  default['mysql']['ebs_vol_size'] = 50
end

default['mysql']['allow_remote_root']               = false
default['mysql']['tunable']['back_log']             = "128"
default['mysql']['tunable']['binlog_format']        = "STATEMENT"
default['mysql']['tunable']['binlog_cache_size']    = "32768"
default['mysql']['tunable']['key_buffer']           = "256M"
default['mysql']['tunable']['max_allowed_packet']   = "16M"
default['mysql']['tunable']['max_connections']      = "800"
default['mysql']['tunable']['max_heap_table_size']  = "32M"
default['mysql']['tunable']['myisam_recover']       = "BACKUP"
default['mysql']['tunable']['net_read_timeout']     = "30"
default['mysql']['tunable']['net_write_timeout']    = "30"
default['mysql']['tunable']['table_open_cache']     = "128"
default['mysql']['tunable']['thread_cache']         = "128"
default['mysql']['tunable']['thread_cache_size']    = 8
default['mysql']['tunable']['thread_concurrency']   = 10
default['mysql']['tunable']['thread_stack']         = "256K"
default['mysql']['tunable']['wait_timeout']         = "180"
default['mysql']['tunable']['query_cache_limit']    = "1M"
default['mysql']['tunable']['query_cache_size']     = "16M"
default['mysql']['tunable']['log_slow_queries']     = "/var/log/mysql/slow.log"
default['mysql']['tunable']['long_query_time']      = 2
default['mysql']['tunable']['expire_logs_days']     = 10
default['mysql']['tunable']['max_binlog_size']      = "100M"
default['mysql']['tunable']['innodb_buffer_pool_size']  = "256M"

###
### instance specific configs are now here, it seems cleaner to have these in the attributes rather 
### than in roles. Ideally some of this seems the function of a data.json, but again, repeated calls 
### to the cloud seems like a really bad idea.
###
default[:mysql][:my_cnf][:bind_address]                       = ipaddress
default[:mysql][:my_cnf][:binlog_format]                      = "STATEMENT"
default[:mysql][:my_cnf][:binlog_cache_size]                  = "32768"
default[:mysql][:my_cnf][:max_connections]                    = "5000"
default[:mysql][:my_cnf][:table_open_cache]                   = "1024"
default[:mysql][:my_cnf][:thread_cache_size]                  = "128"
default[:mysql][:my_cnf][:max_connect_errors]                 = "4294967295"
default[:mysql][:my_cnf][:max_allowed_packet]                 = "16M"
default[:mysql][:my_cnf][:thread_stack]                       = "256K"
default[:mysql][:my_cnf][:tmp_table_size]                     = "128M"
default[:mysql][:my_cnf][:max_heap_table_size]                = "128M"
default[:mysql][:my_cnf][:query_cache_limit]                  = "4M"
default[:mysql][:my_cnf][:query_cache_size]                   = "0"
default[:mysql][:my_cnf][:query_cache_type]                   = "OFF"
default[:mysql][:my_cnf][:key_buffer_size]                    = "32M"
default[:mysql][:my_cnf][:sort_buffer_size]                   = "2M"
default[:mysql][:my_cnf][:join_buffer_size]                   = "2M"
default[:mysql][:my_cnf][:myisam_sort_buffer_size]            = "512M"
default[:mysql][:my_cnf][:read_buffer_size]                   = "8M"
default[:mysql][:my_cnf][:read_rnd_buffer_size]               = "32M"
default[:mysql][:my_cnf][:log_slow_verbosity]                 = "full"
default[:mysql][:my_cnf][:long_query_time]                    = "0.5"
default[:mysql][:my_cnf][:enable_query_response_time_stats]   = "ON"
default[:mysql][:my_cnf][:expand_fast_index_creation]         = "ON"
default[:mysql][:my_cnf][:max_relay_log_size]                 = "0"
default[:mysql][:my_cnf][:relay_log_purge]                    = "1"
default[:mysql][:my_cnf][:relay_log_space_limit]              = "0"
default[:mysql][:my_cnf][:max_binlog_size]                    = "100M"
default[:mysql][:my_cnf][:binlog_do_db]                       = ""
default[:mysql][:my_cnf][:binlog_ignore_db]                   = ""
default[:mysql][:my_cnf][:character_set_server]               = "latin1"
default[:mysql][:my_cnf][:collation_server]                   = "latin1_swedish_ci"
default[:mysql][:my_cnf][:event_scheduler]                    = "OFF"
default[:mysql][:my_cnf][:expire_logs_days]                   = "45"
default[:mysql][:my_cnf][:innodb_buffer_pool_size]            = "2G"
default[:mysql][:my_cnf][:innodb_additional_mem_pool]         = "32M"
default[:mysql][:my_cnf][:innodb_log_buffer_size]             = "8M"
default[:mysql][:my_cnf][:innodb_extra_undoslots]             = "OFF"
default[:mysql][:my_cnf][:innodb_flush_log_at_trx_commit]     = "1"
default[:mysql][:my_cnf][:innodb_support_xa]                  = "0"
default[:mysql][:my_cnf][:sync_binlog]                        = "1"
default[:mysql][:my_cnf][:innodb_flush_method]                = "O_DIRECT"
default[:mysql][:my_cnf][:innodb_log_files_in_group]          = "2"
default[:mysql][:my_cnf][:innodb_log_file_size]               = "256M"
default[:mysql][:my_cnf][:innodb_data_file_path]              = "ibdata1:100M:autoextend"
default[:mysql][:my_cnf][:innodb_open_files]                  = "1000"
default[:mysql][:my_cnf][:innodb_read_io_threads]             = "2"
default[:mysql][:my_cnf][:innodb_write_io_threads]            = "2"
default[:mysql][:my_cnf][:innodb_io_capacity]                 = "200"
default[:mysql][:my_cnf][:innodb_thread_concurrency]          = "0"
default[:mysql][:my_cnf][:userstat]                           = "ON"
