begin
  if Flipper.enabled? :multiuser
    ActiveAdmin.register User do
      permit_params :email, :password, :password_confirmation, :username

      controller do
        defaults finder: :find_by_username
      end

      index do
        selectable_column
        id_column
        column :username
        column :email
        column :current_sign_in_at
        column :sign_in_count
        column :created_at
        actions
      end

      filter :username
      filter :email
      filter :current_sign_in_at
      filter :sign_in_count
      filter :created_at

      form do |f|
        f.inputs do
          f.input :username
          f.input :email
          f.input :password
          f.input :password_confirmation
        end
        f.actions
      end
    end
  end
rescue ActiveRecord::StatementInvalid
  # If we've not migrated Flipper yet, we'll get an exception, which we can swallow
end
