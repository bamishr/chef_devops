name "mysql-cluster-base"
description "Base role for servers Running Percona Cluster MySQL"
run_list(
  "recipe[mysql_percona::firewall-mysql]",
  "recipe[mysql_percona::cluster]"
)
default_attributes(
  "mysql" => {
    "instances" => [
      "thethrum"
    ]
  }
)
