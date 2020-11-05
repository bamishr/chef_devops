#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Cookbook Name:: postfix
# Recipe:: sasl_auth
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "postfix"

sasl_pkgs = []

# We use case instead of value_for_platform_family because we need
# version specifics for RHEL.
case node['platform_family']
when "debian"
  sasl_pkgs = %w{libsasl2-2 libsasl2-modules ca-certificates}
when "rhel"
  if node['platform_version'].to_i < 6
    sasl_pkgs = %w{cyrus-sasl cyrus-sasl-plain openssl}
  else
    sasl_pkgs = %w{cyrus-sasl cyrus-sasl-plain ca-certificates}
  end
when "fedora"
  sasl_pkgs = %w{cyrus-sasl cyrus-sasl-plain ca-certificates}
end

sasl_pkgs.each do |pkg|

  package pkg

end

# define the postmap process to be called after the template has been generated
execute "postmap-sasl_passwd" do
  command "postmap /etc/postfix/sasl_passwd"
  action :nothing
end

# we will use an encrypted data bag for passwords, cause really... 
# This ends up being: hash->array->string
# and is likely better served by another method but one escapes me currently
ses_auth = Chef::EncryptedDataBagItem.load("passwords", "postfix")["ses"].map{|k,v| "#{k}:#{v}"}.join("")

template "/etc/postfix/sasl_passwd" do
  variables(:ses_auth => ses_auth)
  source "sasl_passwd.erb"
  owner "root"
  group "root"
  mode 0400
  notifies :run, "execute[postmap-sasl_passwd]", :immediately
  notifies :restart, "service[postfix]"
end

# now that we have created the encrypted sasl_passwd.db we delete the plain text sasl_passwd file
file "/etc/postfix/sasl_passwd" do
  action :delete
  only_if { File.exists?("/etc/postfix/sasl_passwd") }
end

