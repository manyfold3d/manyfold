class Collection < ApplicationRecord
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable

  acts_as_federails_actor username_field: :public_id, name_field: :name, profile_url_method: :url_for, actor_type: "Group"

  has_many :models, dependent: :nullify
  has_many :collections, dependent: :nullify
  belongs_to :collection, optional: true
  validates :name, uniqueness: {case_sensitive: false}

  # returns all collections at and below given ids
  #   this should be applied to @filters[:collection] to get models in sub-trees
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

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "public_id", "name", "notes", "slug", "updated_at"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["collection", "collections", "links", "models"]
  end
end
