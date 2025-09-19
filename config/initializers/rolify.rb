Rolify.configure do |config|
  # Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
  # config.use_dynamic_shortcuts

  # Configuration to remove roles from database once the last resource is removed. Default is: true
  # config.remove_role_if_empty = false
end

Rails.application.config.after_initialize do
  Role::ROLES.each do |r|
    Role.find_or_create_by name: r
  end
rescue ActiveRecord::StatementInvalid, ActiveModel::UnknownAttributeError
  # Not migrated yet
end
