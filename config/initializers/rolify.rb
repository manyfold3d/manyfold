Rolify.configure do |config|
  # Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
  config.use_dynamic_shortcuts

  # Configuration to remove roles from database once the last resource is removed. Default is: true
  # config.remove_role_if_empty = false
end
