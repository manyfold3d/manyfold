# Blacklist initializer
#
# This initializer defines a blacklist of blocked IP addresses.
#
# Requirements:
# - None
#
# Usage:
# - Add this initializer to your Rails application.
# - Configure the blacklist in this file.
#
# Example:
#   - Block registrations from IP addresses in the blacklist:
#     config.rack_ip.blacklist = ['192.168.1.3', '192.168.1.4']

Manyfold::RackIp.configure do |config|
  config.rack_ip.blacklist = ['192.168.1.3', '192.168.168.4']
end