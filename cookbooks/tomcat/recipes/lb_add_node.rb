#
# Cookbook Name:: thethrum_tomcat
# Recipe:: lb_add_node
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

# check that the expected role exists
if ( node.run_list.roles.include?("tomcat-spof") or node.run_list.roles.include?("tomcat-generic") )
  puts "==============================================================================="
  puts "this is a non-redundant tomcat build... so we will ignore its existence."
  puts "==============================================================================="
else 

require 'rubygems'
require "net/http"

#================================================================
# Ensure we an speak with the F5
#================================================================
# check if the gem is installed, since its not from a provide managed by gem_package and remote_file
# if it is not installed, install it
puts "looking for #{node[:languages][:ruby][:gems_dir]}/gems/f5-icontrol-10.2.0.2"
if ( File.exists?("#{node[:languages][:ruby][:gems_dir]}/gems/f5-icontrol-10.2.0.2") ) 
  puts "found f5-icontrol-10.2.0.2 already installed"
  # require the gem
  require 'f5-icontrol'
else
  # we need the f5 gem to interact with the LB
  # https://devcentral.f5.com/Tutorials/TechTips/tabid/63/articleType/ArticleView/articleId/1086421/Getting-Started-With-Ruby-and-iControl.aspx
  # grab the source
  puts "fetching gems"
  src = "/usr/local/src/f5-icontrol-10.2.0.2.gem"

  # chef does not actually run things in the order that you specify them
  # recipes are not processed like true ruby scripts
  # in order to override this horrendous stupidity it is necessary to wrap 
  # the file installation from the cookbook/files/default in a run_action
  # otherwise chef will process the 'require' function prior to the install,
  # and it will process the install, prior to copying the cookbook file into place
  # seriously, what a pile of suck.
  f = cookbook_file "#{src}" do
    source "f5-icontrol-10.2.0.2.gem"
    owner "root"
    group "root"
    mode "0644"
  end
  f.run_action(:create_if_missing)

  # install the f5 iControl gem
  # this hacky-ness, package do, ':nothing', force 'run_action :install'
  # is the only way to get chef to actually run things in order
  # /hate
  puts "Installing the f5 iControl gem"
  src = "/usr/local/src/f5-icontrol-10.2.0.2.gem"
  r = gem_package "f5-icontrol" do
    source "#{src}"
    action :nothing
  end
  r.run_action(:install)
end

#================================================================
# Now that the f5-icontrol gem is installed, "source" it
#================================================================

# re-read available gems 
Gem.clear_paths

# finally... require the f5 gem
require 'f5-icontrol'

#================================================================
# Identify the Active Load Balancer
#================================================================

# the chef-client pass is managed by the encrypted data_bags/passwords/users.json
# is in keepass
user = "chef-client"
pass = Chef::EncryptedDataBagItem.load("passwords", "users")["#{user}"]

# now that we know we have a node address for the lb lets
# define the active lb
lb_master = ''
lbhosts = Array.[]('lb01.thethrum.com', 'lb02.thethrum.com')
lbhosts.each do |lbhost|
  if lb_master.empty?
    puts "testing lb host #{lbhost}"
    # failover is defined in IControl::System::Failover::FailoverState
    # establish an LB connection
    bigip = F5::IControl.new("#{lbhost}", "#{user}", "#{pass}", ["System.Failover"]).get_interfaces
    failover_state = bigip["System.Failover"].get_failover_state
    puts "found failover_state #{failover_state}"
    #if bigip["System.Failover"].get_failover_state == "FAILOVER_STATE_ACTIVE"
     if "#{failover_state}" == "FAILOVER_STATE_ACTIVE"
      lb_master = lbhost
    end
  end
end

# sanity check
if lb_master.empty?
  puts "failed to find the load balancer active master... dying"
  exit
else 
  puts "lb master is #{lb_master}"
end

#================================================================
# Determine the Node's Load Balancer address
#================================================================
# determine this nodes 10.120 address
node_lb_address = ''
node_lb_int = ''
while node_lb_address.empty?
  node[:network][:interfaces].each do |iface, addrs|
    addrs['addresses'].each do |ip, params|
      if ip.match(/10.120/) and params['family'].eql?('inet')
        node_lb_address = ip
        node_lb_int = iface
      end
    end
  end
end 

# confirm
puts "found node #{node[:fqdn]} lb ip #{node_lb_address} on node interface #{node_lb_int}"

#================================================================
# Check to see if the node exists on the Load Balancer
#================================================================
# Initiate SOAP RPC connection to BIG-IP
bigip = F5::IControl.new(lb_master, user, pass, ['LocalLB.NodeAddress']).get_interfaces

# if the node exists
if bigip['LocalLB.NodeAddress'].get_list.include? node_lb_address
  # see if it has a screen name assigned
  puts "found node #{node_lb_address}, checking screen name"
  begin
    screen_name = bigip['LocalLB.NodeAddress'].get_screen_name(node_lb_address)
    rescue Exception => e  
    puts e.message  
    puts e.backtrace.inspect  
    puts "no screen name found"
  end
  # if no screen name
  if screen_name.nil?
    # set the screen name
    puts "setting the screen name"
    begin
      bigip['LocalLB.NodeAddress'].set_screen_name(node_lb_address,"#{node[:fqdn]}")
      rescue Exceptiona => e
      puts e.message
      puts e.backtrace.inspect
      puts "failed to set screen name"
    end
    # save the LB config
    bigip = F5::IControl.new(lb_master, user, pass, ['System.ConfigSync']).get_interfaces
    bigip['System.ConfigSync'].save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
    puts "BigIP configuration saved"
  end
else 
  # if the node does not exist
  puts "attempting to add the node"
  # create it
  begin
    bigip['LocalLB.NodeAddress'].create(node_lb_address,"0")
    rescue Exception => e
    puts e.message
    puts e.backtrace.inspect
    puts "node creation failed"
  end
  # then set the screen name
  puts "setting the screen name"
  begin
    bigip['LocalLB.NodeAddress'].set_screen_name(node_lb_address,"#{node[:fqdn]}")
    rescue Exception => e
    puts e.message
    puts e.backtrace.inspect
    puts "failed to set screen name"
  end
  # save the LB config
  bigip = F5::IControl.new(lb_master, user, pass, ['System.ConfigSync']).get_interfaces
  bigip['System.ConfigSync'].save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
  puts "BigIP configuration saved"
end

#================================================================
# Determine the pool the node should be in
#================================================================
# Tomcat pools are named "tomcat-"node[:application]-port with a result that matches 
# an existing role, i.e. tomcat-instance
# 
# Our Tomcat listens on port 8080, thus for , thech instance the pools are:
#
#   d-tomcat-instance-8080
#   s-tomcat-instance-8080
#   pr-tomcat-instance-8080
#   tomcat-instance-8080
#

#================================================================
# determine the "environment", we trust nagios configs for this
#================================================================
env = node[:nagios_environment]
puts "found nagios_environment: #{env}"

#================================================================
# map environment to a prefix
#================================================================
prefix_map = {
"dev" => "d-",
"staging" => "s-",
"prerelease" => "pr-",
"prod" => ""
}

# prefix
prefix = prefix_map["#{env}"]
puts "found prefix #{prefix}"

#================================================================
# determine application, and validate that the role/pool exists
#================================================================
# the application from the node
app = node[:application]
node_port = 8080

# check that the expected role exists
if node.run_list.roles.include?("tomcat-#{app}")
  # define the pool
  pool_name = "#{prefix}tomcat-#{app}-#{node_port}"
  puts "defined pool as: #{pool_name}"
else 
  puts "role tomcat-#{app} not found in the run list"
end

# sanity check the pool is defined
if pool_name.empty? 
  puts "failed to determine a pool for this node dying"
  exit
end


#================================================================
# manage the node as a part of the Load Balancer pool
#================================================================
# Ensure that the pool exists on the LB
bigip = F5::IControl.new("#{lb_master}", "#{user}", "#{pass}", ["LocalLB.Pool"]).get_interfaces
unless bigip['LocalLB.Pool'].get_list.include? pool_name
  puts "failed to find pool: #{pool_name} on the LB"
  exit 1
else
  puts "found the pool so checking for this node"
  # collect a list of the existing pool members
  pool_members = bigip['LocalLB.Pool'].get_member([ pool_name ])[0].collect do |pool_member|
    pool_member['address'] + ':' + pool_member['port'].to_s
  end
 
  # don't attempt to add this node if it already exists
  unless pool_members.include?(node_lb_address + ':' + node_port.to_s)
    puts "the node was not in the pool, so adding it"
    bigip['LocalLB.Pool'].add_member([ pool_name ], [[{ 'address' => node_lb_address, 'port' => node_port.to_i }]])
    # save the LB config
    #
    #   SAVE_FULL - Saves a complete configuration that can be used to set up a device from scratch.	 This mode is used to 
    # save a configuration that can be used in a configsync process.	 The filename specified when used with this mode should 
    # NOT have any path information, since the file will be restricted to a specific directory used in configsync. If the
    # specified file does not end with the ".ucs" suffix, a ".ucs" will be automatically appended to the file.
    #
    #   SAVE_HIGH_LEVEL_CONFIG - Saves only the high-level configuration (virtual servers, pools,	 members, monitors...). The 
    # filename specified when used with this	 mode will be ignored, since configuration will be saved to	 /config/bigip.conf by default.
    # 
    #   SAVE_BASE_LEVEL_CONFIG - Saves only the base configuration ( VLANs , self IPs ...). The filename specified when used with 
    # this mode will be ignored, since configuration	 will be saved to /config/bigip_base.conf by default.
    #
    #
    new_bigip = F5::IControl.new(lb_master, user, pass, ['System.ConfigSync']).get_interfaces
    new_bigip['System.ConfigSync'].save_configuration("/config/bigip.conf","SAVE_HIGH_LEVEL_CONFIG")
    puts "BigIP configuration saved"
  else 
    puts "found #{node_lb_address} port #{node_port} already in the pool"
  end
end

# from the opening spof test
end

# from the opening:
# case node[:lsb][:codename]
# when "lucid"
end

