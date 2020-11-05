name "prod"
description "The production environment"
cookbook_versions
default_attributes(
  "app_environment" => "prod",
  "nagios_environment" => "prod",
  "authorization" => { 
    "sudo" => { 
      "groups" => ["admin", "wheel", "sysadmin"],
      "passwordless" => true 
  }
 }
)
