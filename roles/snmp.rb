name "snmp"
description "SNMP and SNMPd for Monitoring"
run_list(
  "recipe[snmp]"
)
default_attributes(
  "application" => "monitoring"
)
# 
override_attributes(
)
