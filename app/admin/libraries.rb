ActiveAdmin.register Library do
  config.batch_actions = false

  actions :all, except: [:new]
  permit_params :path, :name, :notes, :caption, :icon, :storage_service,
    :s3_endpoint, :s3_bucket, :s3_access_key_id, :s3_secret_access_key, :s3_region, tag_regex: []

  Library.ransackable_symbols.each { |it| filter it }

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
  #   permitted << :other if params[:action] == 'create' && current_user.is_administrator?
  #   permitted
  # end

  controller do
    def find_resource
      scoped_collection.find_param(params[:id])
    end
  end
end
