module Linkable
  extend ActiveSupport::Concern

  included do
    has_many :links, as: :linkable, dependent: :destroy
    accepts_nested_attributes_for :links, reject_if: :link_not_valid?, allow_destroy: true

    scope :linked_to, ->(url) { includes(:links).where("links.url": url) }

    def link_not_valid?(attributes)
      attributes[:url].blank? || links.map(&:url).include?(attributes[:url])
    end
  end
end
