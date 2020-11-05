name "aws-base"
description "Default or base role for all aws servers."
run_list(
  "recipe[apt]",
  "recipe[mosh]",
  "recipe[ntp]",
  "recipe[ntp::ntpdate]",
  "recipe[ohai]",
  "recipe[postfix::sasl_auth]",
  "recipe[postfix::aliases]",
  "recipe[postfix::sender_canonical]",
  "recipe[rsyslog]",
  "recipe[users::sysadmins]",
  "recipe[sudo]"
)

default_attributes(
  "chef_client" => {
    "init_style" => "init"
  },
  "nagios" => {
    "checks" => {
      "smtp_host" => "localhost"
    }
  }
)

