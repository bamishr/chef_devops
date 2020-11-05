#
# Cookbook Name:: thethrum_tomcat
# Recipe:: xtralibs_update
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

# this recipe is for a one time run thus a flag is used and cleared
puts "found xtralibs_update #{node[:tomcat][:xtralibs_update]}"
case node[:tomcat][:xtralibs_update]
when "true"

# our tomcat root remains /usr/local/tomcat
tom_home = node[:tomcat][:home]

# update the thethrum xtralibs buffet
puts "updating all thethrum xtralibs"
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

# the CATALINA_BASE is mapped to "runtime" with a symlink
cat_base = "#{tom_home}/thethrum-#{node[:application]}"

# lets wipe the existing libs
puts "wiping the thethrum defined libs"
dest_dir = "#{cat_base}/lib/"
Dir.foreach(dest_dir) do |file| 
  full_path = File.join(dest_dir, file)
  if (file != '.' && file != '..') 
    puts "deleting #{full_path}"
    File.delete(full_path) 
  end
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

# clear the xtralibs_update flag
# node[:tomcat][:xtralibs_update]
puts "resetting the normal flag for xtralibs_update to false."
node.normal["tomcat"]["xtralibs_update"] = "false"
ruby_block "save node data" do
  block do
    node.save
  end
  action :create
end

# from config_update case
end

# from the opening:
# case node[:lsb][:codename]
# when "lucid"
end

