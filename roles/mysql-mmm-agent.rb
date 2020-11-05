name "mysql-mmm-agent"
description "MySQL Servers with an MMM agent"
run_list(
  "recipe[mysql_mmm::mysql-mmm-agent]"
)
