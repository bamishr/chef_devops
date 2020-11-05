name "aws-is-redisio"
description "redisio with aws instance store"
run_list(
  "recipe[redisio::install]",
  "recipe[redisio::enable]"
)

#override_attributes(
#  "redisio" => {
#  }
#)

