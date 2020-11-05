name "aws-ebs-mongodb"
description "aws mongodb with ebs"
run_list(
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb]"
)

#override_attributes(
#  "mongodb" => {
#  }
#)

