#
# Cookbook Name:: rsyslog
# Recipe:: mysql
#
# Copyright 2013, thethrum, Inc.
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

unless Chef::Platform.provider_for_resource(service('syslog-ng') { action :nothing }).load_current_resource.running
  include_recipe "rsyslog::client"

  applogs = data_bag_item("monitoring", "applogs")

  template "/etc/rsyslog.d/mysql.imfile" do
    source "mysql.imfile.erb"
    owner "root"
    group "root"
    mode 0644
    variables :mysql_matches => applogs['mysql']['matches']
    notifies :restart, "service[rsyslog]"
  end

end

