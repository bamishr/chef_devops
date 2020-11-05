name "aws-dev"
description "AWS systems in the dev environment"
#run_list(
#  "recipe[nagios::client]",
#  "recipe[munin::client]"
#)
default_attributes(
  "app_environment" => "dev",
  "nagios_environment" => "dev",
  "lb_environment" => "d-",
  "mysql_environment" => "aws-dev",
  "chef_environment" => "aws-dev"
)
