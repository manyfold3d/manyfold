ActiveAdmin.register ActsAsTaggableOn::Tag, as: "Collections" do
  actions :all, except: [:new]
  controller do
    def scoped_collection
      end_of_association_chain.for_context(:collections)
    end
  end
  permit_params [:name, :notes, :caption]
end
