name "aws-bind"
description "Bind9 servers for AWS Management"
run_list(
  "recipe[bind]"
)

override_attributes(
  "bind9" => {
    "allow_recursion" => "nameservers",
    "allow_transfer" => "nameservers",
    "allow_update" => "internals",
    "zone"     => "thethrum.com",
    "domain"  =>  "thethrum.com",
    "internals" => "10.0.0.0/8",
    "resolver" => "eip of dns server",
    "tsig" => {
      "aws_ddns_tsig" => {
      }
    },
    "configs" => [
      "named.conf",
      "named.conf.acls",
      "named.conf.aws",
      "named.conf.local",
      "named.conf.logging",
      "named.conf.options"
    ],
    "dynamic_zones" => [
      "laws.thethrum.com",
      "paws.thethrum.com",
      "us-east-1a.paws.thethrum.com",
      "us-east-1c.paws.thethrum.com",
      "us-east-1d.paws.thethrum.com",
      "us-east-1a.laws.thethrum.com",
      "us-east-1c.laws.thethrum.com",
      "us-east-1d.laws.thethrum.com"
    ],
    "acls" => {
      "nameservers" =>  [ "localhost", "", "" ],
      "aws" =>  [ "localhost", "10.1.0.0/24", "10.2.0.0/24" ]
    }
  }
)

