#
# Cookbook Name:: thethrum_tomcat
# Recipe:: release-button
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

# sanity check:
# 1. node[:app_environment] needs to be assigned (dev, staging, prod)
# 2. node[:application] needs to be assigned defining the WAR to be installed
case node[:app_environment].nil? or node[:application].nil? 
when true
  puts "

        #######################################################################################

        Hey folks,

        You need to have a defined node[:app_environment] and a defined node[:application]
        or the thethrum_tomcat::source recipe will just ignore you.

        Thank you,
        chef

        #######################################################################################
  "
else 

include_recipe "subversion::client"

# our tomcat root remains /usr/local/tomcat
tom_home = node[:tomcat][:home]

# ensure the xtralibs buffet is up to date
subversion "all thethrum xtralibs" do
  repository node["tomcat"]["build"]["xtralibs_repo"]
  revision "HEAD"
  destination "#{node["tomcat"]["xtralibsdir"]}"
  svn_username "builduser"
  #svn_password ""
  svn_arguments "--force --no-auth-cache"
  user node["tomcat"]["user"]
  group node["tomcat"]["group"]
  action :sync
end

# ensure all of the apps.conf are updated from svn
subversion "all thethrum apps.conf" do
  repository node["tomcat"]["build"]["etc_repo"]
  revision "HEAD"
  destination "#{tom_home}/etc"
  svn_username "builduser"
  #svn_password ""
  svn_arguments "--force --no-auth-cache"
  user node["tomcat"]["user"]
  group node["tomcat"]["group"]
  action :sync
end

# our thethrum specific cat base
cat_base = "#{tom_home}/thethrum-#{node[:application]}"

# lets wipe the runtime libs from thethrum to ensure we are getting a clean install
directory "#{cat_base}/lib/" do
  recursive true
  action :delete
end

# now lets recreate the dir
directory "#{cat_base}/lib" do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

###
### install thethrum and 3rd party libs
###
# open the data_bag of roles
rattrs = data_bag_item("tomcat", "roles")

# get a list of all of the thethrum_xtralibs not part of the default apache-tomcat install
unless rattrs["tomcat-#{node[:application]}"].nil? or rattrs["tomcat-#{node[:application]}"]['xtralibs'].nil? or rattrs["tomcat-#{node[:application]}"]['xtralibs'][node[:nagios_environment]].nil? 
  libsums = rattrs["tomcat-#{node[:application]}"]['xtralibs'][node[:nagios_environment]]
  libsums.each do |k,v|
    puts "found md5sum key #{k} for lib #{v}"
    node.override[:tomcat][:xtralibs][k] = v
    ruby_block "copying role specific or 'xtra' libs into place" do
      block do
        case File.exists?("#{cat_base}/lib/#{v}")
        when true
          case FileUtils.compare_file("#{tom_home}/thethrum-xtralibs/#{v}_#{k}", "#{cat_base}/lib/#{v}")
          when true
            puts "file #{tom_home}/thethrum-xtralibs/#{v}_#{k} found, and matches #{cat_base}/lib/#{v}, so not copying"
          else
            puts "file #{tom_home}/thethrum-xtralibs/#{v}_#{k} found, but does not match #{cat_base}/lib/#{v}"
            puts "copying #{tom_home}/thethrum-xtralibs/#{v}_#{k} to #{cat_base}/lib/#{v}"
            FileUtils.cp "#{tom_home}/thethrum-xtralibs/#{v}_#{k}", "#{cat_base}/lib/#{v}"
          end
        else
          puts "destination file #{cat_base}/lib/#{v} not found"
          puts "copying #{tom_home}/thethrum-xtralibs/#{v}_#{k} to #{cat_base}/lib/#{v}"
          FileUtils.cp "#{tom_home}/thethrum-xtralibs/#{v}_#{k}", "#{cat_base}/lib/#{v}"
        end
      end
      action :create
    end
  end
else 
  puts "

        #######################################################################################

        Hey hey,

        You need to have defined tomcat-role specific libs in data_bags/tomcat/roles.json
        otherwise your CATALINA_BASE will be missing most of what it needs, and the 
        thethrum_tomcat::source recipe will barely get you closer to a working tomcat.

        Thank you,
        chef-client

        #######################################################################################
  "
end

# from the opening:
# sanity check:
# 1. node[:app_environment] needs to be assigned (dev, dev2, staging, prod)
# 2. node[:application] needs to be assigned (generic, site, deal, pogo, etc.)
end

# from the opening:
# case node[:lsb][:codename]
# when "lucid"
end

