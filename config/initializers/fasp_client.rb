FaspClient.configure do |conf|
  conf.authenticate = ->(request) do
    request.env["warden"]&.user&.is_administrator?
  end
  conf.layout = "settings"
  conf.controller_base = "::ApplicationController"
end
