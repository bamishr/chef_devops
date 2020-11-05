name "aws-prod"
description "management of the prod chef environment in aws"
cookbook_versions(
  "apt" => "= 1.9.0",
  "aws" => "= 0.100.6",
  "dynect" => "= 1.0.0",
  "firewall" => "= 0.10.2",
  "activemq" => "= 2.3.0",
  "tomcat" => "= 1.3.0",
  "java" => "= 1.10.2",
  "logrotate" => "= 1.2.0",
  "memcached" => "= 1.3.0",
  "mongodb" => "= 0.11",
  "nginx" => "= 1.7.0",
  "ntp" => "= 1.3.2",
  "ohai" => "= 1.1.8",
  "postfix" => "= 2.1.4",
  "python" => "= 1.3.0",
  "redisio" => "= 1.4.1",
  "rsyslog" => "= 1.5.0",
  "runit" => "= 1.1.4",
  "snmp" => "= 1.0.0",
  "stunnel" => "= 2.0.4",
  "sudo" => "= 2.0.4",
  "sysctl" => "= 0.3.2",
  "ulimit" => "= 0.2.0",
  "users" => "= 1.3.0",
  "varnish" => "= 0.9.4",
  "yum" => "= 2.3.0"
)
default_attributes(
  "authorization" => {
    "sudo" => {
      "groups" => ["admin", "wheel", "sysadmin"], 
      "passwordless" => true
    }
  },
  "nagios_environment" => "aws-prod",
  "app_environment" => "aws-prod"
)
