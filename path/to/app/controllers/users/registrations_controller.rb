# Registrations controller
#
# This controller handles user registrations.
#
# Requirements:
# - rack-ip gem
#
# Usage:
# - Add this controller to your Rails application.
# - Configure the whitelist or blacklist in the `config/initializers/whitelist.rb` or `config/initializers/blacklist.rb` files.

class UsersController::RegistrationsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Get the user's IP address
    ip_address = request.env['HTTP_X_FORWARDED_FOR'] || request.env['REMOTE_ADDR']

    # Check if the IP address is in the whitelist or blacklist
    if config.rack_ip.whitelist.include?(ip_address) || !config.rack_ip.blacklist.include?(ip_address)
      # Allow registration
      super
    else
      # Block registration
      render json: { error: 'Registration blocked due to IP address restrictions' }, status: :forbidden
    end
  end
end