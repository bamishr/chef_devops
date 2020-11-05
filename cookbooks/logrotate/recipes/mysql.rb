if node.run_list.roles.include?('mysql_percona') 
  logrotate_app "mysql" do
    path [
      "/var/log/mysql/*.log"
    ]
    frequency "daily"
    create "644 mysql mysql"
    rotate 3
  end
end
