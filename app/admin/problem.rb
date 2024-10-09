ActiveAdmin.register Problem do
  actions :all, except: [:new]

  controller do
    def find_resource
      scoped_collection.find_param(params[:id])
    end
  end
end
