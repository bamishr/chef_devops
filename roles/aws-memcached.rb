name "aws-memcached"
description "memcached"
run_list(
  "recipe[memcached]"
)

#override_attributes(
#  "memcached" => {
#  }
#)

