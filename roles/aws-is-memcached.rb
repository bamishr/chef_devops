name "aws-is-memcached"
description "aws memcached with instance store"
run_list(
  "recipe[memcached]"
)

#override_attributes(
#  "memcached" => {
#  }
#)

