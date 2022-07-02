ActiveAdmin.register ModelFile do
  actions :all, except: [:new]

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :filename, :model_id, :presupported, :printed, :y_up
  #
  # or
  #
  # permit_params do
  #   permitted = [:filename, :model_id, :presupported, :printed, :y_up]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
end
