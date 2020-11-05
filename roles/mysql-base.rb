name "mysql-base"
description "MySQL Servers"
run_list(
#  "recipe[logrotate::mysql]",
)
default_attributes(
  "mysql" => {
    "instances" => [
      "thethrum"
    ]
  },
  "monitor_group" => "mysql",
  "munin_stats" => {
    "SELECT" => {
      "type" => "multi-stack",
      "stat" => "mysql.*_queries.select"
    },
    "UPDATE" => {
      "type" => "multi-stack",
      "stat" => "mysql.*_queries.update"
    },
    "SLOW" => {
      "type" => "multi-stack",
      "stat" => "mysql.*_slowqueries.queries"
    },
    "load" => {
      "stat" => "load.load"
    }
  }
)
