
# lets get a local svn revision check to measure differences is svn state
execute "svn revision runtime/bin" do
  command "/usr/bin/svn info /usr/local/tomcat/runtime/bin > /usr/local/tomcat/#{node[:fqdn]}-runtime-bin-svn.txt"
  action :run
end

execute "svn revision runtime/bin" do
  command "/usr/bin/svn info /usr/local/tomcat/runtime/lib > /usr/local/tomcat/#{node[:fqdn]}-runtime-lib-svn.txt"
  action :run
end



