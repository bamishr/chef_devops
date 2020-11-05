maintainer       "thethrum, Inc."
maintainer_email "joshua@thethrum.com"
license          "All rights reserved"
description      "Installs/Configures thethrum_tomcat"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"
recipe           "thethrum_tomcat", "Main Tomcat configuration"
%w{ nfs subversion java }.each do |cb|
  depends cb
end
