ActiveAdmin.register Library do
  actions :all, except: [:new]
  permit_params :path
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :path
  #
  # or
  #
  # permit_params do
  #   permitted = [:path]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
end
