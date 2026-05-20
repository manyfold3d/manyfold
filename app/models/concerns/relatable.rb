module Relatable
  extend ActiveSupport::Concern

  included do
    has_many :relationships, dependent: :destroy, as: "subject"
    has_many :object_relationships, dependent: :destroy, class_name: "Relationship", as: "objekt"

    # Add through relationships in models like so:
    # has_many :related_models, through: :relationships, class_name: "Model", source: "objekt"

    # And the invert relationships in models like so:
    # has_many :models_related_to_me, through: :relationships, class_name: "Model", source: "subject"
  end
end
