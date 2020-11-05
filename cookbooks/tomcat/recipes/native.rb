#
# Cookbook Name:: thethrum_tomcat
# Recipe:: native
#
# Copyright 2012, thethrum, Inc.
#
# All rights reserved - Do Not Redistribute
#
case node[:lsb][:codename]
when "lucid"

  # make sure apt is up to date
  execute "apt-get update" do
    action :nothing
  end

  # install the swfdec dependencies and imagemagick which provides `convert`:
  %w{ libapr1-dev libssl-dev openjdk-6-jdk}.each do |package|
    package "#{package}" do
      action :install
      notifies :run, "execute[apt-get update]", :immediately
    end
  end

  # grab the upstream source
  remote_file "#{node[:tomcat][:srcdir]}/tomcat-native-#{node[:tomcat][:native][:version]}-src.tar.gz" do
    source node[:tomcat][:native][:source]
    checksum node[:tomcat][:native][:checksum]
    action :create_if_missing
  end

  # We will compile the native libs for CATALINA_HOME 
  cat_home = node[:tomcat][:cathomedir]

  # 
  bash "Installing Apache Native #{node[:tomcat][:native][:version]} from source" do
    cwd node[:tomcat][:srcdir]
    code <<-EOH
      tar zxvf #{node[:tomcat][:srcdir]}/tomcat-native-#{node[:tomcat][:native][:version]}-src.tar.gz
      cd #{node[:tomcat][:srcdir]}/tomcat-native-#{node[:tomcat][:native][:version]}-src/jni/native
      ./configure \
           --with-apr=/usr/bin/apr-1-config \
           --with-java-home=/usr/lib/jvm/default-java/ \
           --with-ssl=yes \
           --prefix=#{cat_home}
      make -j 6
      make install
    EOH
    not_if { File.exists?("#{node[:tomcat][:srcdir]}/tomcat-native-#{node[:tomcat][:native][:version]}-src") }
  end

# from the opening:
# case node[:lsb][:codename]
# when "lucid"
end
