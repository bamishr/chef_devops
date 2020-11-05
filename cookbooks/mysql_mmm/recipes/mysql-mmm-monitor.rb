#
# Cookbook Name:: mysql_mmm
# Recipe:: mysql-mmm.rb
#
# Copyright 2008-2011, thethrum, Inc.
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

# stripped down for debian
if platform?(%w{debian ubuntu})

  #=====================================================
  # Packages and Software Setup
  #=====================================================
  # make sure apt is up to date
  execute "apt-get update" do
    action :nothing
  end

  # install the sysfs utils
  package "libclass-singleton-perl libnet-arp-perl libaio1" do
    action :install
    notifies :run, "execute[apt-get update]", :immediately
  end

  # I created a deb for the mysql-mmm install, its likely not necessary, but here is how we managed it

  # add the company repository key
  execute "Add Company Lucid repository key" do
    command "curl http://apt.company.com/company-repo-lucid/dists/company-lucid/company_gpg_key.txt | apt-key add -"
  end

  # add the company repo
  file "/etc/apt/sources.list.d/company-repo-lucid.list" do
    content "deb http://apt.company.com/company-repo-lucid/ company-lucid company-main"
    owner "root"
    group "root"
    mode 0644
    not_if {File.exists?("/etc/apt/sources.list.d/company-repo-lucid.list")}
    notifies :run, "execute[apt-get update]", :immediately
  end

  # make sure we have mmm installed, this will install mysql-mmm-common and mysql-mmm-agent
  %w{mysql-mmm-monitor mysql-mmm-tools}.each do |package|
    package "#{package}" do
      action :install
    end
  end

  # delete the default mysql-mmm-monitor init script
  file "/etc/init.d/mysql-mmm-monitor" do
    action :delete
    only_if { File.exists?("/etc/init.d/mysql-mmm-monitor") }
  end

  # remove the service as we dont ever want a "default" mysql-mmm-monitor running
  service "mysql-mmm-monitor" do
    service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
    supports :status => true, :restart => true, :reload => true
    action [ :disable ]
  end

  # get rid of the default monitor configs
  %w{mmm_mon.conf mmm_common.conf mmm_mon_log.conf}.each do |default|
    file "/etc/mysql-mmm/#{default}" do
      action :delete
      only_if { File.exists?("/etc/mysql-mmm/#{default}") }
    end
  end

  # instances are defined in the roles/mmm-mon.rb to allow for assigning 
  # monitoring of instances on a per server basis (i.e. some on sqlbackup01 and some on sqlbackup02)
  node[:mmm][:monitor][:host]["#{node[:fqdn]}"].each do |instance|
    puts "found instance #{instance}"

    # install the mysql-mmm client configs
    template "/etc/mysql-mmm/mmm_mon_#{instance}.conf" do
      source "mmm-server-configs/mmm_mon_#{instance}.conf.erb"
      # define a variable for the instance specific path
      variables(:instance => "#{instance}")
      owner "root"
      group "root"
      mode "0640"
    end

    template "/etc/mysql-mmm/mmm_mon_log_#{instance}.conf" do
      source "mmm-server-configs/mmm_mon_log_INSTANCE.conf.erb"
      # define a variable for the instance specific path
      variables(:instance => "#{instance}")
      owner "root"
      group "root"
      mode "0640"
    end

    template "/etc/mysql-mmm/mmm_common_#{instance}.conf" do
      source "mmm-server-configs/mmm_common_#{instance}.conf.erb"
      # define a variable for the instance specific path
      variables(:instance => "#{instance}")
      owner "root"
      group "root"
      mode "0640"
    end

    # update the /etc/default/mysql-mmm-monitor to be ENABLED
    template "/etc/default/mysql-mmm-monitor" do
      source "default-mysql-mmm-monitor.erb"
      owner "root"
      group "root"
      mode "0640"
    end

    # create the instance specific init script
    template "/etc/init.d/mysql-mmm-monitor-#{instance}" do
      source "init.mysql-mmm-monitor-INSTANCE.erb"
      # define a variable for the instance specific path
      variables(:instance => "#{instance}")
      owner "root"
      group "root"
      mode "0760"
    end
=begin
        # its time to start it up and to ensure it is set to start on boot
        service "mysql-mmm-monitor-#{instance}" do
          supports :status => true, :restart => true, :reload => true
          action [ :enable, :start ]
          not_if "ps ax | grep mmm_mond-#{instance} | grep -v grep"
          only_if { File.exists?("/etc/mysql-mmm/mmm_common_#{instance}.conf") }
        end
=end
  end

# from the opening platform?
end
