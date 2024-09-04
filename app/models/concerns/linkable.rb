module Linkable
  extend ActiveSupport::Concern

  included do
    has_many :links, as: :linkable, dependent: :destroy
    accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true
  end
end
