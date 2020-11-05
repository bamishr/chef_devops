name "nginx-origin"
description "Nginx for Origin Servers"
run_list(
  "recipe[nginx::origin_default]",
  "recipe[nginx::kill_default]",
  "recipe[nginx::headers_more_module]",
  "recipe[nginx::http_gzip_static_module]",
  "recipe[nginx::http_realip_module]",
  "recipe[nginx::http_ssl_module]",
  "recipe[nginx::http_stub_status_module]"
)
default_attributes(
  "application" => "origin",
  "monitor_group" => "nginx",
  "munin" => {
    "client_plugins" => {
      "nginx_memory" => "nginx_memory",
      "nginx_request" => "nginx_request",
      "nginx_status" => "nginx_status"
    }
  },
  "munin_stats" => {
    "Ngninx Requests" => {
      "type" => "stack",
      "stat" => "nginx_request_rate.client_req"
    }
  }
)
#
override_attributes(
  "nginx" => {
    "gzip_vary" => "on",
    "cache_dir" => "/local/cache/nginx",
    "default_site_enabled" => "false",
    "disable_access_log" => "true",
    "disk_cache_max_size" => "1200G",
    "naxsi" => {
      "url" => "https://naxsi.googlecode.com/files/naxsi-core-0.49.tgz",
      "version" => "0.49",
      "checksum" => "7e463d3852b86881e9e880c86184e8ab"
    },
    "worker_processes" => "6" 
  }
)
