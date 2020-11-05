name "aws-ebs-redisio"
description "aws redisio with ebs"
run_list(
  "recipe[redisio::install]",
  "recipe[redisio::enable]",
  "recipe[sysctl]",
  "recipe[ulimit]"
)
default_attributes(
  "ulimit" => {
    "users" => {
      "redis" => {
        "filehandle_limit" => 100000
      }
    }
  },
  "sysctl" => {
    "params" => {
      "vm" => {
        "swappiness" => 0,
        "overcommit_memory" => 1
      },
      "fs" => {
        "file-max" => 100000
      }
    },
    "allow_sysctl_conf" => "true"
  }
)
override_attributes(
  "redisio" => {
    "default_settings" => {
      "datadir" => "/mnt/redis",
      "homedir" => "/mnt/redis"
    }
  }
)

