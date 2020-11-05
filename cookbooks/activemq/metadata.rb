maintainer       "thethrum, Inc."
maintainer_email "ops@thethrum.com"
license          "All rights reserved"
description      "Installs/Configures activemq"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.3.0"
recipe           "activemq", "Apache ActiveMQ installation and configuration"
%w{ java }.each do |cb|
  depends cb
end
