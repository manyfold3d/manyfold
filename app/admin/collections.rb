ActiveAdmin.register Collection do
  actions :all, except: [:new]
  permit_params :name, :notes, :caption

  Collection.ransackable_symbols.each { |x| filter x }
end
