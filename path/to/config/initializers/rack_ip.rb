# Rack IP initializer
#
# This initializer configures Rack IP to block or allow registrations based on IP address.
#
# Requirements:
# - rack-ip gem
#
# Usage:
# - Add this initializer to your Rails application.
# - Configure the whitelist or blacklist in the `config/initializers/whitelist.rb` or `config/initializers/blacklist.rb` files.
#
# Example:
#   - Allow registrations from IP addresses in the whitelist:
#     config.rack_ip.whitelist = ['192.168.1.1', '192.168.1.2']
#   - Block registrations from IP addresses in the blacklist:
#     config.rack_ip.blacklist = ['192.168.1.3', '192.168.1.4']

require 'rack/ip'

module Manyfold
  class RackIp
    def self.configure(app)
      app.config.rack_ip = Rack::IP.new(app.config.rack_ip)
    end
  end
end