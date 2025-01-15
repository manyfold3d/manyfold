ActiveAdmin.register ModelFile do
  actions :all, except: [:new]
  ModelFile.ransackable_symbols.each { |it| filter it }

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :filename, :model_id, :presupported, :y_up
  #
  # or
  #
  # permit_params do
  #   permitted = [:filename, :model_id, :presupported, :y_up]
  #   permitted << :other if params[:action] == 'create' && current_user.is_administrator?
  #   permitted
  # end

  controller do
    def find_resource
      scoped_collection.find_param(params[:id])
    end
  end
end
