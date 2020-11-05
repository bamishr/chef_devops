name "aws-dev"
description "management of the dev chef environment in aws"
cookbook_versions(
  "apt" => "= 1.9.0",
  "postfix" => "= 2.1.4",
  "rsyslog" => "= 1.5.0",
  "aws" => "= 0.100.6",
  "sudo" => "= 2.0.4",
  "dynect" => "= 1.0.0",
  "users" => "= 1.3.0",
  "firewall" => "= 0.10.2",
  "ntp" => "= 1.3.2",
  "ohai" => "= 1.1.8"
)
default_attributes(
  "authorization" => {
    "sudo" => {
      "groups" => ["admin", "wheel", "sysadmin"], 
      "passwordless" => true
    }
  },
  "nagios_environment" => "aws-dev",
  "app_environment" => "aws-dev"
)
