FaspClient.configure do |conf|
  conf.authenticate = ->(request) do
    request.env["warden"]&.user&.is_administrator?
  end
end
