class Collection < ApplicationRecord
  include Followable
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

  has_many :models, dependent: :nullify
  has_many :collections, dependent: :nullify
  belongs_to :collection, optional: true
  belongs_to :creator, optional: true
  validates :name, uniqueness: {case_sensitive: false}
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}
  validates :collection_id, exclusion: {in: ->(it) { Array(it.id) }}

  before_validation :publish_creator, if: :will_be_public?

  validate :validate_publishable

  after_create_commit :after_create
  after_update_commit :after_update

  fasp_share_lifecycle category: "account", uri_method: :fasp_uri

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

  # returns root top-level collections for given ids
  scope :tree_up, ->(id) {
    id ?
    where("collections.id IN (WITH RECURSIVE search_tree(id, path) AS (
      SELECT id, id
      FROM collections
      WHERE collection_id is NULL
    UNION ALL
      SELECT collections.id, path           FROM search_tree
      JOIN collections ON collections.collection_id = search_tree.id
      WHERE NOT collections.id IN (path)
    ) select id from search_tree where id IN (?))", id) : where(collection_id: nil)
  }

  # returns root top-level collections for given collection ids, limited by the top-level ids
  #    top:  @filter[:collection]
  #    id:  collections from models resulting from searches
  scope :tree_both, ->(top, id) {
    top ?
    where("collections.id IN (WITH RECURSIVE search_tree(id, path) AS (
      SELECT id, id
      FROM collections
      WHERE collection_id IN (#{[*top].join(",")})
    UNION ALL
      SELECT collections.id, path           FROM search_tree
      JOIN collections ON collections.collection_id = search_tree.id
      WHERE NOT collections.id IN (path)
    ) select id from search_tree where id IN (?))", id) : tree_up(id)
  }

  #  Basic query that returns list of all collections with their path as csv
  #     WITH RECURSIVE search_tree(id, path) AS (
  #         SELECT id, id
  #         FROM collections
  #         WHERE collection_id is NULL
  #       UNION ALL
  #         SELECT collections.id, path || ',' || collections.id
  #         FROM search_tree
  #         JOIN collections ON collections.collection_id = search_tree.id
  #         WHERE NOT collections.id IN (path)
  #     )  SELECT * FROM search_tree

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
      errors.add :creator, :private if creator && !creator.public?
      errors.add :collection, :private if collection && !collection.public?
    end
  end

  def publish_creator
    creator&.update!(caber_relations_attributes: [{permission: "view", subject: nil}]) unless creator&.public?
  end
end
