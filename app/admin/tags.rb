ActiveAdmin.register ActsAsTaggableOn::Tag, as: "Tags" do
  controller do
    def scoped_collection
      end_of_association_chain.for_context(:tags)
    end
  end
  permit_params :name
end
