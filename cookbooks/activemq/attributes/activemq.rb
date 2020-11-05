# activemq source
default[:activemq][:version]   	= "5.8.0"
default[:activemq][:checksum]  	= "9984316d59544a23fadd4d5f127f4ebc"
default[:activemq][:source]    	= "http://archive.apache.org/dist/activemq/apache-activemq/#{activemq[:version]}/apache-activemq-#{activemq[:version]}-bin.tar.gz"
# config and dirs
default[:activemq][:srcdir]    	= "/usr/local/src"
default[:activemq][:basedir]   	= "/usr/local"
default[:activemq][:dir]       	= "/usr/local/apache-activemq-#{activemq[:version]}"
default[:activemq][:bindir]    	= "#{activemq[:dir]}/bin"
default[:activemq][:datadir]   	= "#{activemq[:dir]}/data/kahadb"
default[:activemq][:configdir] 	= "#{activemq[:dir]}/conf"
default[:activemq][:config]    	= "#{activemq[:configdir]}/activemq.xml"
default[:activemq][:logconfig]   = "#{activemq[:configdir]}/log4j.properties"
default[:activemq][:logdir]    	= "/var/log/activemq"
default[:activemq][:pidfile]   	= "/var/run/activemq.pid"
default[:activemq][:wrapper]	   = "#{activemq[:bindir]}/linux-x86-64/wrapper"
default[:activemq][:wrapconf]	   = "#{activemq[:bindir]}/linux-x86-64/wrapper.conf"

# broker
default[:activemq][:brokerName]  = "from role"
default[:activemq][:master]   	= ""
default[:activemq][:slave]   	   = ""

# connector
default[:activemq][:createConnector] 	= "true"
default[:activemq][:connectorPort] 	   = "9003"
default[:activemq][:jmxDomainName] 	   = "thethrum.com"
default[:activemq][:netConnuri] 	      = "tcp://amq-analytics02.us-east-1c.thethrum.com:61616"

# System
default[:activemq][:memoryUsage]       = "1 gb"
default[:activemq][:storeUsageLimit]   = "1 gb" 
default[:activemq][:storeUsageName]    = "foo"
default[:activemq][:tempUsage] 		   = "100 mb"

# transportConnector
default[:activemq][:TransportConnectorName] 	= "nio" 
default[:activemq][:TransportConnectorURI] 	= "tcp://0.0.0.0:61616"

# logging
default[:activemq][:appender]          = "org.apache.log4j.RollingFileAppender"
default[:activemq][:logfile]  		   = "#{activemq[:logdir]}/activemq.log"
default[:activemq][:maxFileSize]    	= '10MB'
default[:activemq][:maxBackupIndex] 	= '5'
