name "dev"
description "The development environment"
cookbook_versions
default_attributes(
  "app_environment" => "dev",
  "nagios_environment" => "dev"
)
