# tomcat source
default[:tomcat][:version] = "7.0"

default[:tomcat][:user]  = "buildmaster"
default[:tomcat][:group] = "staff"

default[:tomcat][:build]["svn_repo"]      = "https://svn.thethrum.com/web/Infrastructure/trunk/Tomcat/#{tomcat['version']}/"
default[:tomcat][:build]["destination"]   = "/usr/local/tomcat-thethrum-#{tomcat['version']}"
default[:tomcat][:build]["etc_repo"]      = "https://svn.thethrum.com/web/Infrastructure/trunk/Tomcat/#{tomcat['version']}/etc"
default[:tomcat][:build]["tools_repo"]    = "https://svn.thethrum.com/web/Infrastructure/trunk/Tomcat/#{tomcat['version']}/bin"
default[:tomcat][:build]["xtralibs_repo"] = "https://svn.thethrum.com/web/Infrastructure/trunk/Tomcat/xtralibs/#{tomcat['version']}/"

default[:tomcat][:home]            = "/usr/local/tomcat"
default[:tomcat][:log_dir]         = "/var/log/tomcat"
default[:tomcat][:config_dir]      = "/etc/tomcat"

default[:tomcat][:java_options]    = "-Xms2700m -Xmx2700m -XX:MaxPermSize=384m -XX:MaxNewSize=128m -XX:-HeapDumpOnOutOfMemoryError"
default[:tomcat][:jpda]            = "-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"

# tomcat source
default[:tomcat][:sversion]        = "7.0.26"
default[:tomcat][:checksum]        = "89ba5fde0c596db388c3bbd265b63007a9cc3df3a8e6d79a46780c1a39408cb5"
default[:tomcat][:source]          = "http://tomcat.thethrum.com/tomcat-7/v#{tomcat[:sversion]}/bin/apache-tomcat-#{tomcat[:sversion]}.tar.gz"

# tomcat native
default[:tomcat][:native][:version]         = "1.1.23"
default[:tomcat][:native][:source]          = "http://tomcat.thethrum.com/tomcat-connectors/native/#{tomcat[:native][:version]}/source/tomcat-native-#{tomcat[:native][:version]}-src.tar.gz"
default[:tomcat][:native][:checksum]        = "f2a55b5a19adbe491edc98e0c11d9028"

# juli for log4j
default[:tomcat][:juli][:source]            = "http://tomcat.thethrum.com/tomcat-7/v#{tomcat[:sversion]}/bin/extras/tomcat-juli.jar"
default[:tomcat][:juli][:checksum]          = "df3d56bb141209a1f62e28a4b9a54d0c"
default[:tomcat][:juli_adapters][:source]   = "http://tomcat.thethrum.com/tomcat-7/v7.0.26/bin/extras/tomcat-juli-adapters.jar"
default[:tomcat][:juli_adapters][:checksum] = "28979b845fa041111433d9ed891dec9b"

# config and dirs
default[:tomcat][:srcdir]      = "/usr/local/src"
default[:tomcat][:tomdir]      = "/usr/local/tomcat"
default[:tomcat][:thethrumbasedir] = "/usr/local/tomcat/runtime"
default[:tomcat][:thethrumbindir]  = "/usr/local/tomcat/bin"
default[:tomcat][:tomverdir]   = "/usr/local/tomcat/apache-tomcat-#{tomcat[:sversion]}"
default[:tomcat][:cathomedir]  = "/usr/local/tomcat/CATALINA_HOME"
default[:tomcat][:catbasedir]  = "/usr/local/tomcat/runtime"
default[:tomcat][:xtralibsdir] = "#{tomcat[:tomdir]}/thethrum-xtralibs"
default[:tomcat][:logdir]      = "/var/log/tomcat"
default[:tomcat][:piddir]      = "/var/run/tomcat"

# oneoff recipes
default[:tomcat][:config_update]      = "false"
default[:tomcat][:xtralibs_update]    = "false"

# logging
#default[:tomcat][:appender]       = "org.apache.log4j.RollingFileAppender"
#default[:tomcat][:logfile]        = "#{tomcat[:logdir]}/tomcat.log"
#default[:tomcat][:maxFileSize]       = '10MB'
#default[:tomcat][:maxBackupIndex]    = '5'

