module Relatable
  extend ActiveSupport::Concern

  included do
    has_many :relationships, dependent: :destroy, as: "subject"
    has_many :reverse_relationships, dependent: :destroy, class_name: "Relationship", as: "objekt"

    accepts_nested_attributes_for :relationships

    # Add through relationships in models like so:
    # has_many :related_models, through: :relationships, source_type: "Model", source: "objekt"

    # And the invert relationships in models like so:
    # has_many :models_related_to_me, through: :relationships, source_type: "Model", source: "subject"
  end
end
