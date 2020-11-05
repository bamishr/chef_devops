# fqdn and roles are examples only.
name "mysql-mmm-monitor"
description "Servers Acting as MySQL MMM Monitors"
run_list(
  "recipe[mysql_mmm::mysql-mmm-monitor]"
)
default_attributes(
  "mmm" => {
    "monitor" => {
      "host" => {
        "#{fqdn}" => [
          "mysqlrole1",
          "mysqlrole2",
          "mysqlrole3",
          "mysqlrole4"
        ]
      }
    }
  }
)

