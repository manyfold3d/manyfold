module Linkable
  extend ActiveSupport::Concern

  included do
    has_many :links, as: :linkable, dependent: :destroy
    accepts_nested_attributes_for :links, reject_if: :link_not_valid?, allow_destroy: true

    scope :linked_to, ->(url) { includes(:links).where("links.url": url) }

    def link_not_valid?(attributes)
      return false unless attributes.has_key?(:url)
      attributes[:url].blank? || links.where.not(id: attributes[:id]).map(&:url).include?(attributes[:url]) || !UrlSafety.public?(attributes[:url])
    end
  end
end
