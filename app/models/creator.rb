class Creator < ApplicationRecord
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable

  acts_as_federails_actor username_field: :slug, name_field: :name, profile_url_method: :url_for

  has_many :models, dependent: :nullify
  validates :name, uniqueness: {case_sensitive: false}

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "public_id", "name", "notes", "slug", "updated_at"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["links", "models"]
  end

  def to_param
    slug
  end

  def self.find_param(param)
    find_by!(slug: param)
  end

  def summary_html
    return unless caption || notes
    "<section>#{"<header>#{caption}</header>" if caption}#{Kramdown::Document.new(notes).to_html.rstrip if notes}</section>"
  end

  def self.create_from_activitypub_object(actor)
    matches = actor.extensions["summary"].match(/<section><header>(.+)<\/header><p>(.+)<\/p><\/section>/)
    create(
      name: actor.name,
      slug: actor.username,
      links_attributes: actor.extensions["attachment"]&.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} },
      caption: matches[1],
      notes: matches[2],
      federails_actor: actor
    )
  end

  def to_activitypub_object
    {
      "@context": {
        manyfold: "http://manyfold.app/ns#",
        toot: "http://joinmastodon.org/ns#",
        attributionDomains: {
          "@id": "toot:attributionDomains",
          "@type": "@id"
        },
        concreteType: {
          "@id": "manyfold:concreteType",
          "@type": "@string"
        }
      },
      summary: summary_html,
      attributionDomains: [
        [Rails.application.default_url_options[:host], Rails.application.default_url_options[:port]].compact.join(":")
      ],
      concreteType: "Creator",
      attachment: links.map { |it| {type: "Link", href: it.url} }
    }
  end
end
