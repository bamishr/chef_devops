name "aws-is-mongodb"
description "aws mongodb with instance store"
run_list(
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb]"
)

#override_attributes(
#  "mongodb" => {
#  }
#)

