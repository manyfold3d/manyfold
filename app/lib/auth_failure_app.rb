class AuthFailureApp < Devise::FailureApp
  def respond
    super
    # Set response code from warden throw if set
    self.status = warden_options[:status] if warden_options[:status]
  end
end
