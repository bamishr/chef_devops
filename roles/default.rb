name "default"
description "Default role for all servers."
run_list(
  "recipe[ohai]",
  "recipe[dynect::ec2]",
  "recipe[apt]",
  "recipe[ufw::databag]",
  "recipe[users::sysadmins]",
  "recipe[sudo::default]",
  "recipe[nagios::client]",
  "recipe[packages::default]",
  "recipe[ntp::default]",
  "recipe[ntp::ntpdate]",
  "recipe[postfix::ses]"
)

default_attributes(
  "chef_client" => {
    "init_style" => "init"
  },
  "nagios" => {
    "checks" => {
      "smtp_host" => "localhost"
    }
  },
  "munin" => {
    "client_plugins" => {
    }
  },
  "dynect" => {
    "customer" => "thethrum",
    "username" => "",
    "password" => "",
    "zone"     => "thethrum.com",
    "domain"  =>  "thethrum.com"
  },
  "ntp" => {
    "servers" => ["0.us.pool.ntp.org", "1.us.pool.ntp.org","2.us.pool.ntp.org","3.us.pool.ntp.org"]
  }
)
