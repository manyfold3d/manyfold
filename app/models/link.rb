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

  def remove_duplicates!
    Link.where.not(id: id).where(linkable: linkable, url: url).destroy_all # rubocop:disable Pundit/UsePolicyScope
  end

  def self.find_duplicated
    Link.select(:linkable_type, :linkable_id, :url) # rubocop:disable Pundit/UsePolicyScope
      .group([:linkable_type, :linkable_id, :url])
      .having("count(*) > 1").map do |it|
      Link.find_by(linkable_type: it.linkable_type, linkable_id: it.linkable_id, url: it.url)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["created_at", "id", "linkable_id", "linkable_type", "updated_at", "url"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["linkable"]
  end
end
