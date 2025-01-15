ActiveAdmin.register User do
  config.batch_actions = false

  permit_params :email, :password, :password_confirmation, :username, role_ids: []
  User.ransackable_symbols.each { |it| filter it }

  controller do
    defaults finder: :find_by_username

    # Allow form to be submitted without a password
    def update
      if params[:user][:password].blank?
        params[:user].delete "password"
        params[:user].delete "password_confirmation"
      end
      super
    end
  end

  show do
    attributes_table do
      row :username
      row :email
      row :roles
      row :created_at
      row :updated_at
    end
    attributes_table title: "Settings" do
      row :pagination_settings
      row :renderer_settings
      row :tag_cloud_settings
      row :problem_settings
      row :file_list_settings
    end
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
    f.inputs "Basics" do
      f.input :username
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.inputs "Permissions" do
      f.input :roles, as: :check_boxes
    end
    f.inputs "Settings" do
      f.input :pagination_settings
      f.input :renderer_settings
      f.input :tag_cloud_settings
      f.input :problem_settings
      f.input :file_list_settings
    end
    f.actions
  end

  controller do
    def find_resource
      scoped_collection.find_param(params[:id])
    end
  end
end
