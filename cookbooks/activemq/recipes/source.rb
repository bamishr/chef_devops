#
# Cookbook Name:: activemq
# Recipe:: source
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

# create the activemq user
user "activemq" do
  comment "Apache ActiveMQ, APP"
  system true
  shell "/bin/false"
end

# make sure we have installed java
include_recipe "java"

# make our needed dirs
[node[:activemq][:dir], node[:activemq][:configdir], node[:activemq][:logdir], node[:activemq][:bindir], node[:activemq][:datadir]].each do |dir|
  directory dir do
    owner "activemq"
    group "activemq"
    mode 0755
    recursive true
  end
end

# if we dont have activemq running install it
unless `ps -A -o command | grep "[a]ctivemq"`.include?(node[:activemq][:version])
  # ensuring we have this directory
  directory node[:activemq][:srcdir]
  remote_file "#{node[:activemq][:srcdir]}/apache-activemq-#{node[:activemq][:version]}-bin.tar.gz" do
    source node[:activemq][:source]
    checksum node[:activemq][:checksum]
    action :create_if_missing
  end

  bash "Installing ActiveMQ #{node[:activemq][:version]} from source" do
    cwd "/usr/local"
    code <<-EOH
      tar zxf #{node[:activemq][:srcdir]}/apache-activemq-#{node[:activemq][:version]}-bin.tar.gz
    EOH
  end

  environment = File.read('/etc/environment')
  unless environment.include? node[:activemq][:dir]
    File.open('/etc/environment', 'w') { |f| f.puts environment.gsub(/PATH="/, "PATH=\"#{node[:activemq][:bindir]}:") }
  end
end

# add the activemq log file
file node[:activemq][:logfile] do
  owner "activemq"
  group "activemq"
  mode 0644
  action :create_if_missing
  backup false
end

nodes = search(:node, "role:aws-activemq AND nagios_environment:#{node.nagios_environment} AND NOT name:#{node[:thethrum][:fqdn]}")
found = nodes.sample
master = found[:thethrum][:fqdn]
puts "================================================"
puts "master is #{master}"
puts "================================================"


case node[:app_environment]
when "aws-dev"
template node[:activemq][:config] do
  source "dev.activemq.xml.erb"
  variables(:master => "#{master}")
  owner "activemq"
  group "activemq"
  mode 0644
end
when "aws-staging"
template node[:activemq][:config] do
  source "staging.activemq.xml.erb"
  variables(:master => "#{master}")
  owner "activemq"
  group "activemq"
  mode 0644
end
when "aws-prod"
template node[:activemq][:config] do
  source "prod.activemq.xml.erb"
  variables(:master => "#{master}")
  owner "activemq"
  group "activemq"
  mode 0644 
end
end

template node[:activemq][:logconfig] do
  source "log4j.properties.erb"
  owner "activemq"
  group "activemq"
  mode 0644
end

template "/etc/init.d/activemq" do
  source "activemq.init.erb"
  mode 0755
end

=begin
# create munin plugin confs
plugin_confs = node[:munin][:plugin_confs]
plugin_confs.each do |conf|
  template "/usr/share/munin/plugins/jmxquery/#{conf}" do
    source "#{conf}.erb"
    owner "root"
    group "root"
    mode 0755
    notifies :restart, resources(:service => "munin-node")
  end
end
=end

service "activemq" do
  supports :start => true, :stop => true, :restart => true
  action [:enable, :start]
  subscribes :restart, resources(:template => node[:activemq][:config])
  subscribes :start, resources(:template => "/etc/init.d/activemq")
end

