class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  validates :url, uniqueness: {scope: :linkable} # rubocop:disable Rails/UniqueValidationWithoutIndex

  def host
    URI.parse(url).host || url
  rescue URI::InvalidURIError, URI::InvalidComponentError
    url
  end

  def site
    PublicSuffix.parse(host).sld
  rescue PublicSuffix::DomainInvalid
    host
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["created_at", "id", "linkable_id", "linkable_type", "updated_at", "url"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["linkable"]
  end
end
