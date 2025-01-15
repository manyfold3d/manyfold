ActiveAdmin.register Collection do
  actions :all, except: [:new]
  permit_params :name, :notes, :caption

  Collection.ransackable_symbols.each { |it| filter it }

  controller do
    def find_resource
      scoped_collection.find_param(params[:id])
    end
  end
end
