#
# Cookbook Name:: mysql_percona
# Recipe:: grants.rb
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

  # grants are defined by mysql-role
  rattrs = data_bag_item("mysql", "roles")

  # perms
  mysql_perms = Chef::EncryptedDataBagItem.load("passwords", "mysql")

  # use the mysql-base role to identify/define all mysql instances
  # this is done to support multiple instances per box, and to standardize file system paths
  # instances are generally the same as roles, mysql-reports for a reports instance. 
  # Where we have multiple identified DB per instance... multiple customers per DB for example, each instance path will be created.
  # For each instance, if the node has been assigned the "mysql-#{role}"
  # install that mysql config
  node[:mysql][:instances].each do |instance|
    puts "found instance #{instance}"
    puts "looking for mysql-#{instance} in grants"
    if node.run_list.roles.include?("mysql-#{instance}") 
      # Let's make sure the new instance has all of the expected perms
      #
      # 1. The debian-sys-maint user
      # 2. Replication users, slave, master perms
      # 3. Client/App perms
      # 4. thethrum End User Perms (QA, dev, staging, jenkins, monitoring, etc.)
      #

      # we will first establish the grants array that will be processed by erubis/templates once passed
      client_grants = Array.new
      user_grants = Array.new
     
      # lets parse grants per role in the mysql servers run_list
      node[:roles].each do |role|
        puts "found run_list role #{role}"
        # check to see if the mysql/roles.json data_bag has references for this role
        unless rattrs["#{role}"].nil? or rattrs["#{role}"]['grants'].nil?
          # for each grant in the data_bag for that role
          rattrs["#{role}"]['grants'].keys().each do |grole|
            # get the user and perms that are to be assigned
            rattrs["#{role}"]['grants']["#{grole}"].each do |user,perms| 
              puts "found data bag grant role #{grole} with user #{user} and perms #{perms}"
              # prepare an array of all of the clients that will be assignd the perms defined in the data_bag as belonging to the role
              clients = Array.new
              # find all the clients (app servers) that are to receive the perms, and populate the client array with the fqdn
              search(:node, "role:#{grole} AND mysql_environment:#{node.chef_environment}") do |n|
                puts "search found node #{n[:fqdn]} with role #{grole} AND role: #{node.chef_environment}"
                clients << n[:fqdn]
              end
              # for each client/appserver to be assigned the perms 
              clients.each do |client|
                # validate that we have a correctly populated password DB
                unless "#{mysql_perms['app_users']["#{node.chef_environment}"]["#{user}"]}".nil?
                  #  process the array of perms
                  rattrs["#{role}"]['grants']["#{grole}"]["#{user}"].each do |perm|
                    # define the grant as user + perms @ client
                    puts "defining grant: #{perm} TO '#{user}'\@'#{client}' IDENTIFIED BY PASSWORD '#{mysql_perms['app_users']["#{node.chef_environment}"]["#{user}"]}'"
                    unless mysql_perms['app_users']["#{node.chef_environment}"]["#{user}"].nil?
                      grant = "#{perm} TO '#{user}'\@'#{client}' IDENTIFIED BY PASSWORD '#{mysql_perms['app_users']["#{node.chef_environment}"]["#{user}"]}';"
                      # add the grant to the grants array to be passed to the template for processing 
                      puts "adding grant to array: #{grant}"
                      client_grants << grant
                    end
                  end
                end
              end
            end
          end
        end
        unless rattrs["#{role}"].nil? or rattrs["#{role}"]['users'].nil?
          # for each grant in the data_bag for that role
          rattrs["#{role}"]['users'].keys().each do |urole|
            rattrs["#{role}"]['users']["#{urole}"].each do |ufrom,uperm|
              puts "found urole #{urole} with user #{ufrom} and perm #{uperm}"
              #  process the array of perms
              rattrs["#{role}"]['users']["#{urole}"]["#{ufrom}"].each do |uperm|
                mysql_perms["#{urole}"].each do |uuser,upass|
                  puts "found mysql_perms permrole user #{uuser} and pass #{upass}"
                  # define the grant as user + perms @ client
                  puts "defining grant: #{uperm} TO '#{uuser}'\@'#{ufrom}' IDENTIFIED BY PASSWORD '#{upass}'"
                  grant = "#{uperm} TO '#{uuser}'\@'#{ufrom}' IDENTIFIED BY PASSWORD '#{upass}';"
                  # add the grant to the grants array to be passed to the template for processing 
                  puts "adding grant to array: #{grant}"
                  user_grants << grant
                end
              end
            end
          end
        end
        unless rattrs["#{role}"].nil? or rattrs["#{role}"]['plural_grants'].nil?
          # for each extra env in play
          rattrs["#{role}"]['plural_grants'].keys().each do |env|
            # for each role in the data_bag for that env
            rattrs["#{role}"]['plural_grants']["#{env}"].keys().each do |prole|
              rattrs["#{role}"]['plural_grants']["#{env}"]["#{prole}"].each do |puser,pperm|
                puts "found prole #{prole} with user #{puser} and perms #{pperm}"
                # prepare an array of all of the clients that will be assignd the perms defined in the data_bag as belonging to the role
                clients = Array.new
                # find all the clients (app servers) that are to receive the perms, and populate the client array with the fqdn
                search(:node, "role:#{prole} AND role:#{env}") do |n|
                  puts "search found node #{n[:fqdn]} with prole #{prole} AND penv: #{env}"
                  clients << n[:fqdn]
                end
                # for each client/appserver to be assigned the perms 
                clients.each do |client|
                  # validate that we have a correctly populated password DB
                  unless "#{mysql_perms['app_users']["#{node.chef_environment}"]["#{puser}"]}".nil?
                    #  process the array of perms
                    rattrs["#{role}"]['plural_grants']["#{env}"]["#{prole}"]["#{puser}"].each do |perm|
                      # define the grant as user + perms @ client
                      puts "defining grant: #{pperm} TO '#{puser}'\@'#{client}' IDENTIFIED BY PASSWORD '#{mysql_perms['app_users']["#{env}"]["#{puser}"]}'"
                      unless mysql_perms['app_users']["#{env}"]["#{puser}"].nil?
                        grant = "#{pperm} TO '#{puser}'\@'#{client}' IDENTIFIED BY PASSWORD '#{mysql_perms['app_users']["#{env}"]["#{puser}"]}';"
                        # add the grant to the grants array to be passed to the template for processing 
                        puts "adding grant to array: #{grant}"
                        client_grants << grant
                      end
                    end
                  end
                end
              end
            end
          end
        end
      # end of role processing
      end
      # we will write the grants as a per instance sql file to be applied
      grants_path = "/local/mysql-#{instance}/etc/mysql/#{instance}_mysql_grants.sql"
      puts "found your grant file #{grants_path}"
      begin
        t = resources("template[#{grants_path}]")
      rescue
        Chef::Log.info("Could not find previously defined #{instance}_mysql_grants.sql resource")
        t = template grants_path do
          source "grants.sql.erb"
          owner "root"
          group "root"
          mode "0600"
          variables(:mysql_debian_passwd => mysql_perms['admin_users']['debian-sys-maint'],
                    :mysql_repl_passwd => mysql_perms['admin_users']['repl'],
                    :clustercheck_passwd => mysql_perms['admin_users']['clustercheck'],
                    :client_grants => client_grants,
                    :user_grants => user_grants)
          action :create
        end
      end

     # we are generating the grants file above, but not applying here. This process will need some attention as we look to how 
     # accounts will be managed/defined going forward
      # apply grants/create accounts
      bash "Setting Default Accounts" do
        code <<-EOH
          /usr/bin/mysql -S /var/run/mysqld/mysqld-#{instance}.sock -p#{mysql_perms['admin_users']['root']} < /local/mysql-#{instance}/etc/mysql/#{instance}_mysql_grants.sql
        EOH
      end
      
    # close for this instance
    end
  # close for all the instances
  end
# from the opening platform?
end
