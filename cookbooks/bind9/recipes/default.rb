#
# Cookbook Name:: bind9
# Recipe:: default
#
# Copyright 2013, Joshua Levine
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

package "bind9" do
  case node[:platform]
  when "centos", "redhat", "suse", "fedora"
    package_name "bind"
  when "debian", "ubuntu"
    package_name "bind9"
  end
  action :install
end

service "bind9" do
  supports :status => true, :reload => true, :restart => true
  action [ :enable, :start ]
end

# package %w{ libdns-ruby rubygems }

# install keys
# Kaws_ddns_tsig.+157+57405.key
# Kaws_ddns_tsig.+157+57405.private
# Kzone_xfer_key.+157+25161.key
# Kzone_xfer_key.+157+25161.private

# process all config templates, these come from the role
node[:bind9][:configs].each do |config|

template "/etc/bind/#{config}" do
  source "#{config}.erb"
  owner "root"
  group "root"
  mode 0644
end

end


# manage ddns
public_ddns_zone = "public.#{n['ec2']['placement_availability_zone']}.#{n['thethrum']['domain']}"
local_ddns_zone = "local.#{n['ec2']['placement_availability_zone']}.#{n['thethrum']['domain']}"

variables aws_ddns_tsig


