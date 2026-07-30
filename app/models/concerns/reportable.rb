module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reports, class_name: "Fedipub::Moderation::Report", as: :object, dependent: :destroy
  end
end
