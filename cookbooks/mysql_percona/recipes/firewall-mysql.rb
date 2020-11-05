#
# Cookbook Name:: firewall
# Recipe:: mysql
#
# Copyright 2011, thethrum, Inc.
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
# Sets the region to my region as we don't want to set abritrary rules for regions outside my "lan"
region = "#{node['ec2']['placement_availability_zone']}"
region.chop!
region_match = region[0,7]

# searches for nodes with the mysql-instance and in my own region and for each one of them does...
nodes = search(:node, "role:mysql-#{instance}")
puts "found nodes: #{nodes}"
nodes.each do |n|
  puts "processing node: #{n}"
  # allow each node to talk to me on the defined ports
  firewall_rule "mysql-haproxy-check" do
    ports [9200]
    protocol :tcp
    action  :allow
  end
end

