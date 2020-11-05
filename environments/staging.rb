name "staging"
description "The Staging environment"
cookbook_versions
default_attributes(
  "app_environment" => "staging",
  "nagios_environment" => "staging",
  "authorization" => { 
    "sudo" => { 
      "groups" => ["admin", "wheel", "sysadmin"],
      "passwordless" => true 
  }
 }
)
