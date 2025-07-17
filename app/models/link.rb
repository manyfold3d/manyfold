class Link < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  validates :url, presence: true, uniqueness: {scope: :linkable} # rubocop:disable Rails/UniqueValidationWithoutIndex

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

  def deserializer
    self.class.deserializer_for(url: url, for_class: linkable.class)
  end

  def self.deserializer_for(url:, for_class: nil)
    [
      Integrations::Cults3d::CreatorDeserializer,
      Integrations::Cults3d::ModelDeserializer,
      Integrations::MyMiniFactory::CreatorDeserializer,
      Integrations::MyMiniFactory::CollectionDeserializer,
      Integrations::MyMiniFactory::ModelDeserializer,
      Integrations::Thangs::ModelDeserializer,
      Integrations::Thingiverse::CreatorDeserializer,
      Integrations::Thingiverse::CollectionDeserializer,
      Integrations::Thingiverse::ModelDeserializer
    ].map do |klass|
      klass.new(uri: url)
    end.find { |it| it.valid?(for_class: for_class) }
  end

  def update_metadata_from_link_later(organize: false)
    UpdateMetadataFromLinkJob.perform_later(link: self, organize: organize)
  end
end
