name "varnish-origin"
description "Varnish for Origin Servers"
run_list(
  "recipe[varnish::origin]"
)
default_attributes(
  "application" => "origin",
  "monitor_group" => "varnish",
  "varnish" => {
    "nsfiles" => 131072,
    "memlock" => 82000,
    "min_threads" => 500,
    "max_threads" => 2000,
    "thread_timeout" => 120,
    "sess_workspace" => 32768,
    "storage_file" => "/var/lib/varnish/$INSTANCE/varnish_storage.bin",
    "storage_size" => {
      "dev" => "1G",
      "staging" => "1G",
      "prod" => "10G"
    },
    "ttl" => "10",
    "vcls" => {
      "dev" => [
        "origin-404.html",
        "origin-5xx.html",
        "origin-backends.vcl",
        "origin-default.vcl",
        "origin-secret"
      ],
      "prod" => [
        "origin-404.html",
        "origin-5xx.html",
        "origin-backends.vcl",
        "origin-default.vcl",
        "origin-secret"
      ]
    },
    "debs" => [
      "varnish_3.0.3-1_amd64.deb",
      "libvarnishapi-dev_3.0.3-1_amd64.deb",
      "libvarnishapi1_3.0.3-1_amd64.deb",
      "varnish-dbg_3.0.3-1_amd64.deb",
      "varnish-doc_3.0.3-1_all.deb"
    ],
    "vmods" => [
      "libvmod_var.a",
      "libvmod_var.la",
      "libvmod_var.so"
    ]
  },
  "url_purge_tool" => {
    "broker" => {
        "dev" => "failover:(tcp://d-jms01.thethrum.com:61616,tcp://d-jms02.thethrum.com:61616)",
        "stg" => "failover:(tcp://s-jms01.thethrum.com:61616,tcp://s-jms02.thethrum.com:61616)",
        "prod" => "failover:(tcp://jms01.thethrum.com:61616,tcp://jms02.thethrum.com:61616)"
    }
  },
  "varnishncsa" => {
    "daemon" => "/usr/bin/varnishncsa",
    "client" => "/usr/bin/varnishncsa -f -c -P /var/run/varnishncsa-c.pid",
    "backend" => "/usr/bin/varnishncsa -f -b -P /var/run/varnishncsa-b.pid",
    "wrapper" => "/usr/bin/logger",
    "syslog_channel" => "local0.info",
    "syslog_tag" => "varnish_cdn_client"
  },
  "munin" => {
    "client_plugins" => {
      "varnish_allocations" => "varnish_",
      "varnish_backend_traffic" => "varnish_",
      "varnish_data_structures" => "varnish_",
		"varnish_expunge" => "varnish_",
		"varnish_hit_rate" => "varnish_",
		"varnish_losthdr" => "varnish_",
		"varnish_lru" => "varnish_",
		"varnish_memory_usage" => "varnish_",
		"varnish_objects" => "varnish_",
		"varnish_objects_per_objhead" => "varnish_",
		"varnish_objoverflow" => "varnish_",
		"varnish_obj_sendfile_vs_write" => "varnish_",
		"varnish_request_rate" => "varnish_",
		"varnish_session_herd" => "varnish_",
		"varnish_shm" => "varnish_",
		"varnish_shm_writes" => "varnish_",
		"varnish_threads" => "varnish_",
		"varnish_transfer_rates" => "varnish_",
      "varnish_uptime" => "varnish_",
      "varnish_vcl_and_purges" => "varnish_"
    }
  },
  "munin_stats" => {
    "Varnish Requests" => {
      "type" => "stack",
      "stat" => "varnish_request_rate.client_req"
    },
    "Varnish Load" => {
      "stat" => "load.load"
    }
  }
)
override_attributes(
  "varnish" => {
    "vmoddir" => "/usr/lib/x86_64-linux-gnu/varnish/vmods"
  }
)
