ActiveAdmin.register Collection do
  actions :all, except: [:new]
  permit_params :name, :notes, :caption
end
