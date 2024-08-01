class Collection < ApplicationRecord
  include Followable

  has_many :models, dependent: :nullify
  has_many :collections, dependent: :nullify
  has_many :links, as: :linkable, dependent: :destroy
  belongs_to :collection, optional: true
  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true
  validates :name, uniqueness: {case_sensitive: false}
  validates :slug, uniqueness: true

  before_validation :slugify_name, if: :name_changed?

  default_scope { order(:name) }
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
    ["caption", "created_at", "id", "name", "notes", "slug", "updated_at"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["collection", "collections", "links", "models"]
  end

  private

  def slugify_name
    self.slug = name.parameterize
  end
end
