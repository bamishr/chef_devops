name "mysql-thethrum"
description "Core thethrum MySQL Servers"
default_attributes(
  "munin" => {
    "client_plugins" => {
      "mysql-site_bytes" => "multi-mysql/mysql_bytes",
      "mysql-site_queries" => "multi-mysql/mysql_queries",
      "mysql-site_queries_ext" => "multi-mysql/mysql_queries_ext",
      "mysql-site_replication_lag" => "multi-mysql/mysql_replication_lag",
      "mysql-site_slowqueries" => "multi-mysql/mysql_slowqueries",
      "mysql-site_threads" => "multi-mysql/mysql_threads"
    }
  },
  "munin_stats" => {
    "site_SELECT" => {
      "type" => "combo",
      "stat" => "mysql_thethrum_queries.select"
    },
    "site_UPDATE" => {
      "type" => "combo",
      "stat" => "mysql_thethrum_queries.update"
    },
    "site_SLOW" => {
      "type" => "combo",
      "stat" => "mysql_thethrum_slowqueries.queries"
    },
    "load" => {
      "stat" => "load.load"
    }
  },
  "mysql" => {
    "instances" => [
      "thethrum"
    ],
    "my_cnf" => {
      "wsrep_provider_options" => "socket.ssl_cert=/local/mysql-thethrum/etc/mysql/ssl/mysql-cluster-thethrum-cert.pem;socket.ssl_key=/local/mysql-thethrum/etc/mysql/ssl/mysql-cluster-thethrum-key.pem;evs.keepalive_period=PT3S;evs.inactive_check_period=PT10S;evs.suspect_timeout=PT30S;evs.inactive_timeout=PT1M;evs.install_timeout=PT1M",
      "ssl_ca" => "/local/mysql-thethrum/etc/mysql/ssl/mysql-thethrum-ca-cert.pem",
      "ssl_cert" => "/local/mysql-thethrum/etc/mysql/ssl/mysql-thethrum-server-cert.pem",
      "ssl_key" => "/local/mysql-thethrum/etc/mysql/ssl/mysql-thethrum-server-key.pem"
    }
  }
)
run_list(
)
