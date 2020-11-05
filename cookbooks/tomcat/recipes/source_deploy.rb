#
# Cookbook Name:: thethrum_tomcat
# Recipe:: deploy
#
# Copyright 2011, thethrum, Inc.
#
# All rights reserved - Do Not Redistribute
#
case node[:lsb][:codename]
when "lucid"

include_recipe "thethrum_tomcat::source"

# required by buildinstall.py
package "curl"

case node[:application]
when 'generic'
  puts 'not managing apps.conf if it exists, as this is a generic role'
  # ln -s /usr/local/tomcat/etc/apps.conf.prod.hotel /etc/tomcat/apps.conf
  link "#{node['tomcat']['config_dir']}/apps.conf" do
    to "#{node['tomcat']['homedir']}/thethrum-#{node[:application]}/etc/tomcat/apps.conf.#{node['app_environment']}.#{node['application']}"
    not_if { ::File.symlink?("/etc/tomcat/apps.conf") }
  end
when 'pr'
  puts 'managing apps.conf as if it were prod, as this is the PR role'
  link "#{node['tomcat']['config_dir']}/apps.conf" do
    to "#{node['tomcat']['homedir']}/thethrum-#{node[:application]}/etc/tomcat/apps.conf.prod.#{node['application']}"
    not_if { ::File.symlink?("/etc/tomcat/apps.conf") }
  end 
else
  link "#{node['tomcat']['config_dir']}/apps.conf" do
    to "#{node['tomcat']['tomdir']}/etc/tomcat/apps.conf.#{node['app_environment']}.#{node['application']}"
  end
end

end
