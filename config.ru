# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

map ActionController::Base.config.relative_url_root || “/” do
    run Rails.application
    Rails.application.load_server
end