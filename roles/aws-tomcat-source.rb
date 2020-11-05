name "aws-tomcat-source"
description "Tomcat Servers Built From Source"
run_list(
  "recipe[rsyslog::tomcat]",
  "recipe[logrotate::tomcat]",
  "recipe[python::requests]",
  "recipe[tomcat::source]",
#  "recipe[tomcat::lb_add_node]"
#  "recipe[tomcat::native]"
  "recipe[tomcat::parse_apps]"
)
default_attributes(
  "monitor_group" => "tomcat",
  "munin_stats" => {
    "catalina_requests" => {
      "type" => "stack",
      "stat" => "jmx_catalina_requests.catalina_request_count"
    },
    "load" => {
      "stat" => "load.load"
    }
  },
  "munin" => {
    "client_plugins" => {
      "jmx_catalina_requests" => "jmxquery/jmx_",
      "jmx_catalina_threads" => "jmxquery/jmx_",
      "jmx_catalina_times" => "jmxquery/jmx_",
      "jmx_catalina_traffic" => "jmxquery/jmx_",
      "jmx_java_cpu" => "jmxquery/jmx_",
      "jmx_java_process_memory" => "jmxquery/jmx_",
      "jmx_java_threads" => "jmxquery/jmx_",
      "clog_errors" => "log01/clog_errors",
      "log_errors" => "log01/log_errors",
      "log_warns" => "log01/log_warns"
    }
  }
)
