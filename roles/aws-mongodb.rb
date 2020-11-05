name "aws-mongodb"
description "mongodb"
run_list(
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb]"
)

#override_attributes(
#  "mongodb" => {
#  }
#)

