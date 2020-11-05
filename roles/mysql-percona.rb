name "mysql-percona"
description "Servers Running Percona MySQL"
run_list(
  "recipe[mysql_percona::server]"
)
