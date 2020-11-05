name "aws-redisio"
description "redisio"
run_list(
  "recipe[redisio::install]",
  "recipe[redisio::enable]"
)

#override_attributes(
#  "redisio" => {
#  }
#)

