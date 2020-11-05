name "aws-prod"
description "AWS systems for the prod environment"
#run_list(
#  "recipe[nagios::client]",
#  "recipe[munin::client]"
#)
default_attributes(
  "app_environment" => "aws-prod",
  "nagios_environment" => "aws-prod",
  "lb_environment" => "",
  "mysql_environment" => "aws-prod",
  "chef_environment" => "aws-prod"
)
