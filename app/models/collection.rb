class Collection < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.collection")

  include Followable
  include Talkative
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable
  include Indexable
  include FaspClient::DataSharing::Lifecycle

  broadcasts_refreshes

  acts_as_federails_actor(
    username_field: :public_id,
    name_field: :name,
    profile_url_method: :url_for,
    # We use the Group actor type purely so Mastodon doesn't ignore the actor.
    # Actual type is differentiated with f3di:concreteType == "Collection".
    # Ideally this would be a Collection: https://www.w3.org/TR/activitystreams-vocabulary/#dfn-collection
    # Hopefully at some point this can change, if Mastodon starts allowing other actor types
    # See https://github.com/mastodon/mastodon/issues/22322
    actor_type: "Group"
  )

  has_and_belongs_to_many :models # rubocop:disable Rails/HasAndBelongsToMany
  has_many :collections, dependent: :nullify
  belongs_to :collection, optional: true
  belongs_to :creator, optional: true
  belongs_to :preview_model, class_name: "Model", optional: true

  validates :name, uniqueness: {case_sensitive: false}, length: SAFE_NAME_LENGTH
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}
  validates :collection_id, exclusion: {in: ->(it) { Array(it.id) }}
  validates :preview_model, inclusion: {in: :models, allow_nil: true}

  before_validation :publish_creator, if: :will_be_public?

  validate :validate_publishable

  after_create_commit :after_create
  after_update_commit :after_update

  fasp_share_lifecycle category: "account", uri_method: :fasp_uri, only_if: :public_and_indexable?

  def fasp_uri
    federails_actor&.federated_url
  end

  def name_with_domain
    remote? ? name + " (#{federails_actor.server})" : name
  end

  # returns all collections at and below given ids
  #   used in Search::FilterService#parameter(:collection) to get models in sub-trees
  scope :tree_down, ->(id) {
    id ?
    where("collections.id IN (With RECURSIVE search_tree(id) AS (
      select id from collections where id IN (#{[*id].join(",")})
      union all
      select collections.id from search_tree join collections on collections.collection_id = search_tree.id where NOT collections.id IN (search_tree.id)
    ) select id from search_tree)") : where(collection_id: nil)
  }

  def to_activitypub_object
    ActivityPub::CollectionSerializer.new(self).serialize
  end

  def after_create
    Activity::CollectionPublishedJob.set(wait: 5.seconds).perform_later(id) if public?
  end

  def after_update
    Activity::CollectionPublishedJob.set(wait: 5.seconds).perform_later(id) if just_became_public?
  end

  def validate_publishable
    # If the model will be public
    if caber_relations.find { |it| it.subject.nil? }
      # Check required fields
      # i18n-tasks-use t("activerecord.errors.models.collection.attributes.creator.private")
      errors.add :creator, :private if creator && !creator.public?
      # i18n-tasks-use t("activerecord.errors.models.collection.attributes.collection.private")
      errors.add :collection, :private if collection && !collection.public?
    end
  end

  def publish_creator
    creator&.update!(caber_relations_attributes: [{permission: "view", subject: nil}]) unless creator&.public?
  end
end
