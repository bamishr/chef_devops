#
# Copyright:: Copyright (c) 2012, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "postfix"

execute "update-postfix-aliases" do
  command "newaliases"
  action :nothing
end

# I have added a data bag to manage aliases
#   data_bags/postfix/aliases.json
# We will process the data.json to populate the template
aliases = data_bag_item("postfix", "aliases")["accounts"]

# generate the template
template "/etc/aliases" do
  source "aliases.erb"
  variables(:aliases => aliases)
  notifies :run, "execute[update-postfix-aliases]"
end
