name "aws-activemq"
description "Servers that run activemq"
run_list(
  "recipe[activemq::source]"
)
default_attributes(
  "munin" => {
    "client_plugins" => {
      "jmx_java_cpu" => "jmxquery/jmx_",
      "jmx_java_process_memory" => "jmxquery/jmx_",
      "jmx_java_threads" => "jmxquery/jmx_",
      "amq-analytics_enqueuedequeue" => "jmxquery/jmx_",
      "amq-analytics_enqueuetime" => "jmxquery/jmx_",
      "amq-analytics_inflightcounts" => "jmxquery/jmx_",
      "amq-analytics_queuesizes" => "jmxquery/jmx_",
      "amq-analytics_totalmessages" => "jmxquery/jmx_"
    },
    "plugin_confs" => [
      "amq-analytics_FileDescriptors.conf",
      "amq-analytics_enqueuedequeue.conf",
      "amq-analytics_enqueuetime.conf",
      "amq-analytics_inflightcounts.conf",
      "amq-analytics_queuesizes.conf",
      "amq-analytics_totalmessages.conf"
    ]
  }
)

