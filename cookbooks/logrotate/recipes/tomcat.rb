if node.run_list.roles.include?('loghost') 
  logrotate_app "tomcat" do
    path [
      "/local/rsyslog/web/tomcat/access.log",
      "/local/rsyslog/web/tomcat/catalina.out",
      "/local/rsyslog/web/tomcat/pyramid-gameprogress.log"
    ]
    frequency "daily"
    create "644 buildmaster staff"
    rotate 3
  end
elsif (node.run_list.roles.include?('tomcat6-base') || node.run_list.roles.include?('tomcat7-base') || node.run_list.roles.include?('tomcat-source'))
  logrotate_app "tomcat" do
    path [
      "/var/log/tomcat/*.log",
      "/var/log/tomcat/catalina.out",
    ]
    frequency "daily"
    create "644 ops staff"
    rotate 3
  end
end
