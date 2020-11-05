#
# Author:: ops@company.com
# Cookbook Name:: postfix
# Recipe:: sender_canonical
#
# Copyright 2009-2012, Comapny, Inc.
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

# in ec2 we are primarily using hosts that are configured by DHCP
# the end result is values like:
#
#  "public_hostname": "ec2-23-22-249-51.compute-1.amazonaws.com",
#  "local_hostname": "ip-10-29-175-250.ec2.internal",
#  etc.
#
# Thus, in the same way we manage company specific definitions of fqdn and domain, 
# independent of the amazon values, we need to ensure we control the outbound mail values 
# and more specifically, we want to ensure they appear as coming from our chosen domain.
#
# This need is met by the /etc/postfix/sender_canonical

service "postfix" do
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

template "/etc/postfix/sender_canonical" do
  source "sender_canonical.erb"
  owner "root"
  group 0
  mode 00644
  notifies :restart, "service[postfix]"
end

