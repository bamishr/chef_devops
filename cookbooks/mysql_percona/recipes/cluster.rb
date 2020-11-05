#
# Cookbook Name:: mysql_percona
# Recipe:: server.rb
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

sumo_source 'mysql' do
    path '/var/log/mysql/*'
    category 'mysql'  # optional, defaults to 'log' or the category attr.
    default_timezone 'UTC'  # optional, defaults to UTC or timezone attr.
end

  #=====================================================
  # Packages plus Hardware and System Setup
  #=====================================================
  # make sure apt is up to date
 include_recipe "apt"

  # install packages
  # install date-calc is for backups
  # install sysfsutil for optimizations
  # install xinetd for use by clustercheck
  %w{ libdate-calc-perl sysfsutils xinetd }.each do |package|
    package "#{package}" do
      action :install
      notifies  :run, resources(:execute => "apt-get update"), :immediately
    end
  end

  # configure the sysctl.conf
  execute "configure-sysctl" do
    command "echo 'vm.swappiness = 0' >> /etc/sysfs.conf" 
    action :run
    not_if "grep vm.swappiness /etc/sysfs.conf"
  end

  # configure the running kernel swappiness
  execute "configure swappiness" do
    command "echo 0 > /proc/sys/vm/swappiness" 
    action :run
  end

  #================================================================
  # Add the percona repository and install packages
  #================================================================
  # for password generation
  ::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

  # generate all passwords if not managed in the encrypted json
  node.set_unless['mysql']['server_debian_password'] = secure_password
  node.set_unless['mysql']['server_root_password']   = secure_password
  node.set_unless['mysql']['server_repl_password']   = secure_password

  # add the percona apt repository
  #  execute "Add the Percona repository key" do
  #    command "curl http://www.percona.com/downloads/RPM-GPG-KEY-percona | apt-key add -"
  #  end
  apt_repository "percona" do
    uri "http://repo.percona.com/apt"
    distribution "#{node[:lsb][:codename]}"
    components ["main"]
    keyserver "keys.gnupg.net"
    key "1C4CBDCDCD2EFD2A"
    action :add
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end

  # prepare package management/configuration
  #
  # encrypted data.json use to protect the root password used in pre-seeding...
  # The default value for the SECRET_FILE is "/etc/chef/encrypted_data_bag_secret" so this 
  # needs to be copied into place manually as part of initial setup...
  # the key is in keepass, but NOTE the process is picky like ssh_keys, carriage returns = doom

  # look for secret in file pointed to by encrypted_data_bag_secret config.
  # If not set explicitly use default of /etc/chef/encrypted_data_bag_secret
  mysql_perms = Chef::EncryptedDataBagItem.load("passwords", "mysql")

  # pre-seed answers to the percona deb package installs
  # point apt at a config to read
  execute "preseed percona-xtradb-cluster-server" do
    #command "debconf-set-selections /var/cache/local/preseeding/percona-xtradb-cluster-server.seed"
    command "debconf-set-selections /var/cache/local/preseeding/percona-server.seed"
    action :nothing
  end

  # create the pre-seed config to be read
  #template "/var/cache/local/preseeding/percona-xtradb-cluster-server.seed" do
  template "/var/cache/local/preseeding/percona-server.seed" do
    variables(:mysql_root_passwd => mysql_perms['admin_users']['root'])
    source "percona-xtradb-cluster-server.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed percona-xtradb-cluster-server"), :immediately
  end

  # the directory where pre-seed results are stored. This can be used to verify passed variables
  directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  # remove default mysql foo if installed since it clashes with percona
  %w{mysql-client-core-5.5  mysql-common}.each do |package|
    package "#{package}" do 
      action :purge
      notifies :run, resources(:execute => "apt-get update"), :immediately
    end
  end

  # install the percona server package, this will install:
  #    libaio1 libmysqlclient18 percona-server-client-5.5 percona-server-common-5.5 percona-server-server-5.5
  %w{percona-xtradb-cluster-client-5.5 percona-xtradb-cluster-server-5.5 percona-xtrabackup percona-toolkit}.each do |package|
    package "#{package}" do 
      action :install
      notifies :run, resources(:execute => "apt-get update"), :immediately
    end
  end

  #============================================================
  # Clean the default install
  #============================================================
  # define the default service, and kill it as we dont ever want a "default" mysql running
  # from a percona cookbook. Default needs can be met by the default mysql cookbook.
  service "mysql" do
    service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
    supports :status => true, :restart => true, :reload => true
    action [ :disable, :stop ]
    only_if { File.exists?("/etc/init.d/mysql") }
  end

  # delete the default mysql scripts and configs
  %w{ /etc/logrotate.d/percona-xtradb-cluster-server-5.5 /etc/init.d/mysql /var/log/mysql.log /var/log/mysql.err}.each do |file|
    file "#{file}" do
      action :delete
      only_if { File.exists?("#{file}") }
    end
  end

  # wipe the default mysql configs
  %w{/etc/mysql}.each do |directory|
    directory "#{directory}" do
      action :delete
      recursive true
    end
  end

  #============================================================
  # Admin Power
  #============================================================
  # master admin password
  # install the /root/.my.cnf 
  template "/root/.my.cnf" do
    # pass from the encrypted data.json, and define a variable for the instance specific socket
    variables(:mysql_root_passwd => mysql_perms['admin_users']['root'])
    source "dot.my.cnf.erb"
    owner "root"
    group "root"
    mode "0600"
  end

  # instances are generally the same as roles
  # Exceptions include where we have multiple identified DB per instance...  adding a customer specific mysql-cust or internal, mysql-ops, for example.
  # for each instance, if the node has been assigned the "mysql-#{role}"
  # install that mysql config

  #============================================================
  # Create Instance specific directories
  #============================================================
  node[:mysql][:instances].each do |instance|
    puts "found instance #{instance}"
    puts "looking for mysql-#{instance} in the node's run list"

    if node.run_list.roles.include?("mysql-#{instance}") 

      #============================================================
      # Create the persisitent config directories
      #============================================================
      # create the needed dir root
      directory "/local/mysql-#{instance}" do
        owner "mysql"
        group "mysql"
        action :create
        recursive true
      end

      %w{etc etc/mysql}.each do |dir|
        # create the needed dir tree
        directory "/local/mysql-#{instance}/#{dir}" do
          owner "mysql"
          group "mysql"
          action :create
        end
      end

      #============================================================
      # Create the ephemeral data directories
      #============================================================
      directory "/mnt/mysql-#{instance}" do
        owner "mysql"
        group "mysql"
        action :create
        recursive true
      end

      %w{data bin-log relay-log}.each do |dir|
        # create the needed dir tree
        directory "/mnt/mysql-#{instance}/#{dir}" do
          owner "mysql"
          group "mysql"
          action :create
        end
      end

      #============================================================
      # Create the instance specific configs
      #============================================================
      # create the debian.cnf 
      template "/local/mysql-#{instance}/etc/mysql/debian.cnf" do
        # pass from the encrypted data.json, and define a variable for the instance specific socket
        variables(:mysql_debian_passwd => mysql_perms['admin_users']['debian-sys-maint'], :sock => "/var/run/mysqld/mysqld-#{instance}.sock")
        source "debian.cnf.erb"
        owner "root"
        group "root"
        mode "0600"
      end

      # sets the node attribute for the socket for use in other recipes
     node.set['mysql']['socket'] = "/var/run/mysqld/mysqld-#{instance}.sock"

      # install the server certs
      remote_directory "/local/mysql-#{instance}/etc/mysql/ssl" do
        source "ssl"
        owner "mysql"
        group "mysql"
        files_owner "mysql"  
        files_group "mysql"
        files_mode 0400
        mode 0766
      end

      # create the instance specific init script
      template "/etc/init.d/mysql-cluster-#{instance}" do
        # define a variable for the instance specific path
        variables(:instance_prefix => "/local/mysql-#{instance}", :instance => "#{instance}")
        source "mysql-cluster-init.erb"
        owner "root"
        group "root"
        mode "0760"
      end

      # enable rc.d scripts for mysql-#{role}
      service "mysql-cluster-#{instance}" do
        supports :restart => true, :reload => true, :status => true
        action [:enable]
      end

      # create the instance specific logrotate config
      # note: I leave the defaults from percona and FAI in place for now. I am not sure
      # there is any advantage to removing them, and if present, they address defaults.
      template "/etc/logrotate.d/mysql-#{instance}" do
        # define a variable for the instance specific path
        variables(:instance => "#{instance}")
        source "mysql-role.logrotate.erb"
        owner "root"
        group "root"
        mode "0644"
      end

      # install the instance specific mysql config
      # I have broken out attribute variables into a few different data_bags. The my.cnf shares allot of default attributes that I have left in
      # cookbooks/mysql_percona/attributes/default.rb but uses a data_bags/mysql/roles.json to provide role specific attribute overrides and a 
      # data_bags/mysql/nodes.json to define node specific attribute over-ride. Examples of use are:
      #
      # 1. All prod mysql instances are measured as if they have at least 6 disks and thus have innodb_io_capacity, innodb_read_io_threads, innodb_write_io_threads
      #    that are significantly different than what is desired as a default for virtual machines, and perhaps the cloud, so the role over-rides are in data_bags/mysql/roles.json
      #    and decisions will be made based on performance testing.
      #
      # 2. server-id settings and bind-address settings are per node/ip so those are in data_bags/mysql/nodes.json 
      #    The default will be to listen to all interfaces, but this will allow for the creation of large cloud based, multi-mysql instances per host, if desired in the future.
      # 
      # To process the overriding variables we process the data_bags in order of specificity, so first for roles, and then for nodes, setting specific data 
      # from the data_bags we then use to override the node defaults, here the changes are specific to the my.cnf
      #
      # the override attrs from the role.json
      # This causes a round-trip to the server for each overriding attribute in the data bag.
      rattrs = data_bag_item("mysql", "roles")
      myrattrs = rattrs[node.chef_environment]['my_cnf']
      myrattrs.each do |k,v|
        puts "found role key #{k} value #{v}"
        node.override[:mysql][:my_cnf][k] = v
      end

      # the override attrs from the node.json
      # This causes a round-trip to the server for each overriding attribute in the data bag.
      # the whole point here is to have node specific my.cnf attributes over-riding the default from
      # a data_bag, and having them set as node attributes to me measured for other tasks.
      nattrs = data_bag_item("mysql", "nodes")
      mynattrs = nattrs[node[:fqdn]]['my_cnf']
      mynattrs.each do |k,v|
        puts "found node key #{k} value #{v}"
        node.override[:mysql][:my_cnf][k] = v
      end

      #======================================================================================
      # this is purely a memory structure of each cluster holding data about all its nodes
      #======================================================================================
      # Define the node's region to determine LAN vs WAN communication
      region = "#{node['ec2']['placement_availability_zone']}"
      region.chop!
      region_match = region[0,7]

      # find all cluster nodes
      servers = search(:node, "role:mysql-#{instance} AND chef_environment:#{node.chef_environment}")
      unless servers.empty?
        servers.each do |server| 
          region = "#{server['ec2']['placement_availability_zone']}"
          fqdn = "#{server[:fqdn]}"
          public_ipv4 = "#{server[:ec2][:public_ipv4]}"
          local_ipv4 = "#{server[:ec2][:local_ipv4]}"

          # lets build our data structure
          if node.override[:mysql][:cluster_addresses].empty?
            node.override[:mysql][:cluster_addresses] = {}
          end

          #node.override[:mysql][:cluster_addresses]["#{region}"] = {}
          node.override[:mysql][:cluster_addresses]["#{region}"]["#{fqdn}"] = {}
          node.override[:mysql][:cluster_addresses]["#{region}"]["#{fqdn}"][:public_ipv4] = "#{public_ipv4}"
          node.override[:mysql][:cluster_addresses]["#{region}"]["#{fqdn}"][:local_ipv4] = "#{local_ipv4}"

        end
      end

      # the variable in play will start as 
      wsrep_cluster_address = 'EMPTY_CLUSTER_ADDRESS'

      # First we will look to see if this is the first node of a new cluster, or if existing nodes exist
      # If no existing cluster nodes exists in aws we assume a new cluster, else the server will use any found node as its wsrep_cluster_address
      # Note: We have to remove self from the list of donors.
      nodes = search(:node, "role:mysql-#{instance} AND chef_environment:#{node.chef_environment} AND NOT hostname:#{node.name}")
      # Check for nil nodes
      if nodes.empty?
        wsrep_cluster_address = 'gcomm://'
        # Since this appears to ve the first node of a new cluster, with no existing nodes to act as donors for the cluster...
        # copy the default /var/lib/mysql/* data files as they are our core structure configured by the package install
        # if, and only if, the initial DB does not exist, and this is the primary master, as defined by the wsrep_cluster_address
        if (wsrep_cluster_address == "gcomm://")
          puts "found new or solo node with wsrep_cluster_address: #{wsrep_cluster_address}"
          if (!File.exists?("/local/mysql-#{instance}/data/ibdata1"))
            # install the base DB (user tables, perms, etc.)
            bash "Installing Default MySQL DB" do
              code <<-EOH
                rsync -av --exclude ib_logfile* --exclude ibdata1 /var/lib/mysql/ /mnt/mysql-#{instance}/data/
              EOH
            end
          end
        end
      else
        # donor nodes were found
        puts "found mysql-#{instance} potential donor nodes for this server: #{nodes}"
        # if there are multiples, pick a random sample
        donor = nodes.sample
        puts "found donor node: #{donor}"
        wsrep_cluster_address = "gcomm://#{donor[:ec2][:public_ipv4]}"
        puts "wsrep_cluster_address is: #{wsrep_cluster_address}"
      end

      # create the instance specific my.cnf
      template "/local/mysql-#{instance}/etc/mysql/my.cnf" do
        # define a variable for the instance specific path
        variables(:instance_prefix => "/local/mysql-#{instance}", 
                  :instance_data_prefix => "/mnt/mysql-#{instance}",
                  :instance => "#{instance}", 
                  :mysql_root_passwd => mysql_perms['admin_users']['root'],
                  :wsrep_cluster_address => "#{wsrep_cluster_address}"
        )
        source "cluster-my.cnf.erb"
        owner "mysql"
        group "mysql"
        mode "0664"
      end

      # Let's write our node data
      unless Chef::Config[:solo]
        ruby_block "save node data" do
          block do
            node.save
          end
          action :create
        end
      end
 
      # now that we have established our mysql instance install and config, its time to start it up and to ensure it is set to start on boot
      service "mysql-cluster-#{instance}" do
        supports :status => true, :restart => true, :reload => true
        action [ :enable, :start ]
        not_if "ps ax | grep /local/mysql-#{instance}/etc/mysql/my.cnf | grep -v grep"
        #only_if { File.exists?("/local/mysql-#{instance}/data/mysql/db.frm") }
      end

      # clustercheck is a monitoring script provided to track the status of the percona cluster, we are fixing the user and pass here
      template "/usr/bin/clustercheck" do
        # pass from the encrypted data.json, and define a variable for the instance specific socket
        variables(:clustercheck_passwd => mysql_perms['admin_users']['clustercheck'], :instance => "#{instance}")
        source "clustercheck.erb"
        owner "root"
        group "root"
        mode "0755"
      end

      # clustercheck runs in xinetd
      template "/etc/xinetd.d/mysqlchk" do
        source "xinetd-mysqlchk.erb"
        owner "root"
        group "root"
        mode "0644"
      end

      # we need to add the service to /etc/services
      execute "update-services" do
        command "echo 'mysqlchk        9200/tcp                        # MySQL check' >> /etc/services"
        action :run
        not_if "grep mysqlchk /etc/services"
      end

      # its time to start xinetd, we trust firewalls here
      service "xinetd" do
        supports :status => true, :restart => true, :reload => true
        action [ :reload ]
        #not_if "ps ax | grep xinetd | grep -v grep"
      end

      if node.run_list.roles.include?("mysql-backup")

        # set up backups
        template "/local/mysql-#{instance}/etc/mysql/mysql-backup.pl" do
          variables(:instance => "#{instance}")
          source "mysql-backup.pl.erb"
          owner "root"
          group "root"
          mode "0640"
        end

        # cron it
        cron "mysql-backup.pl" do
          command "/usr/bin/perl /local/mysql-#{instance}/etc/mysql/mysql-backup.pl"
          user "root"
          mailto "root@company.com"
          hour "*"
          minute "17"
        end
      
      end
 
    else 
      
      # did not find this instance
      puts "did not find instance: mysql-#{instance}"

    end
  end

  # grants
  include_recipe "mysql_percona::grants"

# from the opening platform?
end

