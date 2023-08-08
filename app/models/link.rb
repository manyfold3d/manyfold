class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  def host
    URI.parse(url).host
  end

  def site
    PublicSuffix.parse(host).sld.to_sym
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["created_at", "id", "linkable_id", "linkable_type", "updated_at", "url"]
  end
end
