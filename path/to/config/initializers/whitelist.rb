# Whitelist initializer
#
# This initializer defines a whitelist of allowed IP addresses.
#
# Requirements:
# - None
#
# Usage:
# - Add this initializer to your Rails application.
# - Configure the whitelist in this file.
#
# Example:
#   - Allow registrations from IP addresses in the whitelist:
#     config.rack_ip.whitelist = ['192.168.1.1', '192.168.1.2']

Manyfold::RackIp.configure do |config|
  config.rack_ip.whitelist = ['192.168.1.1', '192.168.1.2']
end