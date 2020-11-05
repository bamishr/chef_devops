name "aws-ebs-memcached"
description "aws memcached with ebs"
run_list(
  "recipe[memcached]"
)

#override_attributes(
#  "memcached" => {
#  }
#)

