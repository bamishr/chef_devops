#
# Cookbook Name:: thethrum_tomcat
# Recipe:: parse_apps
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node[:lsb][:codename]
when "lucid"

apps_conf = "/etc/tomcat/apps.conf"

# to manage run order
case File.exists?("#{apps_conf}") 
when true

# result
result = ''

# grab the file data
contents = File.open(apps_conf).read
# clear all carrige return variations
contents.gsub!(/\r\n?/, "\n")
# Process the apps.conf contents
contents.each_line do |line|
  # get rid of comments
  # ruby somehow has no grep{!/ /} or grep -v equiv
  unless line.match(/(^|\s)#/)
    # the ruby parser for json seems to hate single ticks
    line = line.gsub("\'", "\"")
    result << line
  end
end

# json hash
hash = JSON.parse result

# set the results to the node's data
hash.each do |key|
  name = key["name"]
  node.default[:tomcat]["apps"][name] = {}
  node.default[:tomcat]["apps"][name]["number"] = key["number"]
  node.default[:tomcat]["apps"][name]["war"] = key["war"]
  node.default[:tomcat]["apps"][name]["warPath"] = key["warPath"] unless key["warPath"].nil?
end

# preserve our node data 
unless Chef::Config[:solo]
ruby_block "save node data" do
  block do
    node.save
  end
    action :create
  end
end

# close case apps.conf
end

# from the opening:
#   case node[:lsb][:codename]
#   when "lucid"
end

