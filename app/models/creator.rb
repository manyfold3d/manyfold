class Creator < ApplicationRecord
  include ApplicationUploader::Attachment(:avatar)
  include ApplicationUploader::Attachment(:banner)
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable
  include Indexable
  include FaspClient::DataSharing::Lifecycle

  broadcasts_refreshes

  acts_as_federails_actor username_field: :slug, name_field: :name, profile_url_method: :url_for
  fasp_share_lifecycle category: "account", uri_method: :fasp_uri, only_if: :public_and_indexable?

  has_many :models, dependent: :nullify
  has_many :collections, dependent: :nullify
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :slug, presence: true, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}, format: {with: /\A[[:alnum:]\-_]+\z/}

  # Explicitly explain serialization for MariaDB
  attribute :avatar_data, :json
  attribute :banner_data, :json

  def fasp_uri
    federails_actor&.federated_url
  end

  def name_with_domain
    remote? ? name + " (#{federails_actor.server})" : name
  end

  def to_param
    slug
  end

  def self.find_param(param)
    find_by!(slug: param)
  end

  def to_activitypub_object
    ActivityPub::CreatorSerializer.new(self).serialize
  end
end
