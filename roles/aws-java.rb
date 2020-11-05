name "aws-java"
description "java"
run_list(
  "recipe[java::openjdk]"
)

#override_attributes(
#  "java" => {
#  }
#)

