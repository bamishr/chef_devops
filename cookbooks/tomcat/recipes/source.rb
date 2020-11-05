#
# Cookbook Name:: thethrum_tomcat
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

case node[:lsb][:codename]
when "lucid"

# sanity check:
# 1. node[:app_environment] needs to be assigned (dev, dev2, staging, prod)
# 2. node[:application] needs to be assigned (generic, site, deal, pogo, etc.)
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

include_recipe "nfs"
include_recipe "subversion::client"
include_recipe "java"
include_recipe "thethrum_tomcat::config_update"
include_recipe "thethrum_tomcat::xtralibs_update"

# create required read NFS mounts
node[:tomcat][:mounts].each do |dir, export_name|
  directory "/nfs/#{dir}" do
    recursive true
  end

  mount "/nfs/#{dir}" do
   device "nfs01:/local/drbd/export/#{export_name}"
   fstype "nfs"
   options "timeo=30,rw,soft,intr,rsize=8192,wsize=8192"
   action [:mount, :enable]
  end
end

# create tomcat user
# not needed if user comes from ldap
unless
  case Chef::VERSION
  when /^0\.9\.(\d+)$/
    node.run_list.expand.recipes.include?("openldap::auth")
  else
    node.run_list.expand(node.chef_environment).recipes.include?("openldap::auth")
  end
  user node["tomcat"]["user"] do
    comment "Tomcat User"
    gid node["tomcat"]["group"]
    home node["tomcat"]["home"]
    shell "/bin/false"
    system true
  end
end

# grab the tomcat source
cookbook_file "#{node[:tomcat][:srcdir]}/apache-tomcat-#{node[:tomcat][:sversion]}.tar.gz" do
  source "apache-tomcat-#{node[:tomcat][:sversion]}.tar.gz"
  checksum node[:tomcat][:checksum]
  action :create_if_missing
end

# our tomcat root remains /usr/local/tomcat
tom_home = node[:tomcat][:home]

# We are making that dir, in place of a symlink in this version
tom_home = node[:tomcat][:home]
directory node[:tomcat][:home] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# This release introduces isolation between CATALINA_HOME and CATALINA_BASE. This is desirable for two reasons:
#
#   1. it gets us the ability to roll-out multiple tomcat instances per box 
#   2. it separates upstream Apache jars from thethrum and 3rd party jars
#
# CATALINA_HOME is now /usr/local/tomcat/CATALINA_HOME linked to /usr/local/tomcat/apache-tomcat-version
cat_home = node[:tomcat][:cathomedir]

# we populate our CATALINA_HOME by unpacking our upstream source in the CATALINA_BASE
# we set perms on that which was unpacked
bash "Installing ApacheTomcat #{node[:tomcat][:sversion]} from source" do
  cwd tom_home
  code <<-EOH
    tar zxvf #{node[:tomcat][:srcdir]}/apache-tomcat-#{node[:tomcat][:sversion]}.tar.gz
    chown -R #{node["tomcat"]["user"]}.#{node["tomcat"]["group"]} apache-tomcat-#{node[:tomcat][:sversion]} 
  EOH
  not_if { File.exists?("#{node[:tomcat][:tomverdir]}") }
end

# we get rid of the .bat files
ruby_block "deleting #{cat_home}/bin/*.bat" do
  block do
    FileUtils.rm_r Dir.glob("#{cat_home}/bin/*.bat")
  end
  action :create
end

# and then linking to it
# ln -s /usr/local/tomcat/apache-tomcat-#{node[:tomcat][:sversion]} /usr/local/tomcat/CATALINA_HOME
link cat_home  do
  to node["tomcat"]["tomverdir"] 
end

# there are many files/directories that we do not want from the upstream, so we wipe them here
%w{ conf logs webapps work }.each do |dir|
  directory "#{cat_home}/#{dir}" do
    recursive true
    action :delete
  end
end

# create the CATALINA_HOME cert dir, since we use one cert for every base
%w{ cert }.each do |dir|
  directory "#{cat_home}/#{dir}" do
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0775"
  end
end

# install the thethrum certs
remote_directory "#{cat_home}/cert" do
  source "cert"
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  files_owner node["tomcat"]["user"]
  files_group node["tomcat"]["group"]
  files_mode 0755
  mode 0755
end

# we will not change the use of /etc/tomcat 
# create the apps.conf config dir
directory node["tomcat"]["config_dir"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0755"
end

# nor /var/log/tomcat
# create log directory
directory node["tomcat"]["log_dir"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# we will keep a master store of thethrum libs
# create the thethrum-xtralibs directory
directory node["tomcat"]["xtralibsdir"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# checkout the xtralibs buffet
subversion "all thethrum xtralibs" do
  repository node["tomcat"]["build"]["xtralibs_repo"]
  revision "HEAD"
  destination "#{node["tomcat"]["xtralibsdir"]}"
  svn_username "builduser"
  #svn_password ""
  svn_arguments "--force --no-auth-cache"
  user node["tomcat"]["user"]
  group node["tomcat"]["group"]
  action :checkout
end

# we will now configure log4j in our CATALINA_HOME so that it is GLOBAL for all bases
# If you want to configure Tomcat to use log4j globally:
#
# Put log4j.jar and tomcat-juli-adapters.jar and catalina-jmx-remote from "extras" into $CATALINA_HOME/lib.
# Replace $CATALINA_HOME/bin/tomcat-juli.jar with tomcat-juli.jar from "extras".
#
# I will address the hard-coding ... eventually
ruby_block "copying log4j and jmx related files" do
  block do
    case File.exists?("#{cat_home}/bin/tomcat-juli.jar") 
    when true
      case FileUtils.compare_file("#{tom_home}/thethrum-xtralibs/tomcat-juli.jar_df3d56bb141209a1f62e28a4b9a54d0c", "#{cat_home}/bin/tomcat-juli.jar")
      when true
        puts "file #{tom_home}/thethrum-xtralibs/tomcat-juli.jar_df3d56bb141209a1f62e28a4b9a54d0c found, and matches #{cat_home}/bin/tomcat-juli.jar, so not copying"
      else 
        puts "file #{tom_home}/thethrum-xtralibs/tomcat-juli.jar_df3d56bb141209a1f62e28a4b9a54d0c found, but does not match #{cat_home}/bin/tomcat-juli.jar"
        puts "copying #{tom_home}/thethrum-xtralibs/tomcat-juli.jar_df3d56bb141209a1f62e28a4b9a54d0c to #{cat_home}/bin/tomcat-juli.jar"
        FileUtils.cp "#{tom_home}/thethrum-xtralibs/tomcat-juli.jar_df3d56bb141209a1f62e28a4b9a54d0c", "#{cat_home}/bin/tomcat-juli.jar"
      end
    else 
      puts "destination file #{cat_home}/bin/tomcat-juli.jar not found"
      puts "copying #{tom_home}/thethrum-xtralibs/tomcat-juli-adapters.jar_28979b845fa041111433d9ed891dec9b to #{cat_home}/lib/tomcat-juli-adapters.jar"
      FileUtils.cp "#{tom_home}/thethrum-xtralibs/tomcat-juli-adapters.jar_28979b845fa041111433d9ed891dec9b", "#{cat_home}/lib/tomcat-juli-adapters.jar" 
    end
    case File.exists?("#{cat_home}/lib/catalina-jmx-remote.jar")
    when true
      case FileUtils.compare_file("#{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636", "#{cat_home}/lib/catalina-jmx-remote.jar")
        when true
          puts "file #{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636 found, and matches #{cat_home}/lib/catalina-jmx-remote.jar, so not copying"
        else
          puts "file #{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636 found, but does not match #{cat_home}/lib/catalina-jmx-remote.jar"
          puts "copying  #{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636 to #{cat_home}/lib/catalina-jmx-remote.jar"
          FileUtils.cp " #{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636", "#{cat_home}/lib/catalina-jmx-remote.jar"
        end
      else
        puts "destination file #{cat_home}/lib/catalina-jmx-remote.jar not found"
        puts "copying  #{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636 to #{cat_home}/lib/catalina-jmx-remote.jar"
        FileUtils.cp "#{tom_home}/thethrum-xtralibs/catalina-jmx-remote.jar_9aa01424a3782319bbdff1f0bc37f636", "#{cat_home}/lib/catalina-jmx-remote.jar"
      end
    end
  action :create
end

###
### Managing startup
###
# we install the thethrum specific catalina.sh
if node.run_list.roles.include?("tomcat-jasper")
  template "#{cat_home}/bin/catalina.sh" do
    source "jasper-catalina.sh.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0755"
  end
else 
  template "#{cat_home}/bin/catalina.sh" do
    source "catalina.sh.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0755"
  end
end

# install the startup script
# calculate heap size based on node memory
# heap size = total mem MB - 1024
heap_size = (node["memory"]["total"].to_i / 1024) - 1024
if heap_size <= 512
  heap_size = 512
end

# TODO calculate MaxPermSize based on # of apps
max_perm_size = 384

# the java options to be passed 
case node[:app_environment]
when 'dev'
  node.set["tomcat"]["java_options"] = "-Xms#{heap_size}m -Xmx#{heap_size}m -XX:MaxPermSize=#{max_perm_size}m -XX:MaxNewSize=128m -XX:-HeapDumpOnOutOfMemoryError #{node[:tomcat][:jpda]}"
else
  node.set["tomcat"]["java_options"] = "-Xms#{heap_size}m -Xmx#{heap_size}m -XX:MaxPermSize=#{max_perm_size}m -XX:MaxNewSize=128m -XX:-HeapDumpOnOutOfMemoryError"
end

# render the template
# note: I do not have the pid file PIDF managed on a per role basis, my plan would be to do so
# should we go with multi, simply passing the role in "tomcat-role.init.erb"
#
template "/etc/init.d/tomcat" do
  source "tomcat-source.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

# set the service to start on boot
service "tomcat" do
  supports :restart => true, :reload => false, :status => false
  action [:enable]
end

###
### At this point in the process, we have a base tomcat install in CATALINA_HOME, created from upstream source, and patched 
### to include log4j support. We will now manage thethrum specific installs, meaning thethrum definitions of:
### 
### CATALINA_BASE
###
### For starters, we will assume that the tomcat role is the active base, and thus can be derived based on node[:application]
### as has been true since chef was rolled out. In dev I plan to liberate this notion a bit for end-user convenience.
###
### As with CATALINA_HOME, the CATALINA_BASE will be mapped for thethrum use by a symlink, allowing for: 
###
### 1. multiple installed versions of tomcat to reference one thethrum specific base (bin/conf/lib/webapps) for easy testing
### 2. multiple installed bases to be swapped with a symlink change and a tomcat restart, and no change to tomcat
### 3. Preservation of the thethrum colloquialism 'runtime' tracked as node[:tomcat][:thethrumbasedir]
###
# the CATALINA_BASE will be mapped to "runtime" with a symlink
cat_base = "#{tom_home}/thethrum-#{node[:application]}"

# create the application/role specific CATALINA_BASE directory
directory cat_base do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# link thethrum's expected name to it
# ln -s cat_base /usr/local/tomcat/runtime
link node["tomcat"]["catbasedir"]  do
  to cat_base
end

# create the CATALINA_BASE subdirs
%w{bin conf lib temp webapps }.each do |dir|
  directory "#{cat_base}/#{dir}" do
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0775"
  end
end

# install the CATALINA_BASE specific env/lib script
template "#{cat_base}/bin/setenv.sh" do
  source "setenv.sh.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# install the CATALINA_BASE site-wide files
# catalina.policy, catalina.properties, tomcat-users.xml, web.xml
remote_directory "#{cat_base}/conf" do
  source "conf"
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  files_owner node["tomcat"]["user"]
  files_group node["tomcat"]["group"]
  files_mode 0750
  mode 0755
end

# install the role specific context.xml
#unless node[:app_environment].nil? or node[:application].nil? 
  template "#{cat_base}/conf/context.xml" do
    source "context.xml.#{node[:app_environment]}.#{node[:application]}.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0755"
    not_if { node[:app_environment].nil? or node[:application].nil? }
  end
#end

# install the role specific server.xml
#unless node[:app_environment].nil? or node[:application].nil? 
  template "#{cat_base}/conf/server.xml" do
    source "server.xml.#{node[:app_environment]}.#{node[:application]}.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0755"
    not_if { node[:app_environment].nil? or node[:application].nil? }
  end
#end

# manage the web.xml if required
case node[:tomcat][:webxml]
when "true"
  template "#{cat_base}/conf/web.xml" do
    source "web.xml.#{node[:application]}.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0755"
    not_if { node[:application].nil? }
  end
end

# grab all of the apps.conf from svn
# the link is in the deploy.rb
subversion "all thethrum apps.conf" do
  repository node["tomcat"]["build"]["etc_repo"]
  revision "HEAD"
  destination "#{tom_home}/etc"
  svn_username "builduser"
  svn_password ""
  svn_arguments "--force --no-auth-cache"
  user node["tomcat"]["user"]
  group node["tomcat"]["group"]
  action :checkout
end

# create the base.conf, this is not referenced by startup scripts in this instance
# it has had the functionality replaced with symlinks in /usr/local/tomcat
# however it remains referenced by buildinstall.py 
template "/etc/tomcat/base.conf" do
  source "source.base.conf.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0755"
  variables(
    :tomcat_base => "#{node["tomcat"]["catbasedir"]}"
  )
  not_if { File.exists?("/etc/tomcat/base.conf") }
end

# create the app.properties
template "#{tom_home}/etc/tomcat/app.properties.#{node[:nagios_environment]}" do
  source "app.properties.#{node[:nagios_environment]}.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0755"
end

# and then linking to it
# ln -s /usr/local/tomcat/etc/tomcat/app.properties /etc/tomcat/app.properties
link "/etc/tomcat/app.properties"  do
  to "#{tom_home}/etc/tomcat/app.properties.#{node[:nagios_environment]}" 
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


# Let's write our node data
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end

###
### install the thethrum tools
###
# create the thethrum-tools directory
directory node["tomcat"]["thethrumbindir"] do
  owner node["tomcat"]["user"]
  group node["tomcat"]["group"]
  mode "0775"
end

# check out the tools
subversion "all thethrum tools" do
  repository node["tomcat"]["build"]["tools_repo"]
  revision "HEAD"
  destination node["tomcat"]["thethrumbindir"]
  svn_username "builduser"
  svn_password ""
  svn_arguments "--force --no-auth-cache"
  user node["tomcat"]["user"]
  group node["tomcat"]["group"]
  action :checkout
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

