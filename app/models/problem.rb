class Problem < ApplicationRecord
  include PublicIDable

  belongs_to :problematic, polymorphic: true

  validates :category, uniqueness: {scope: :problematic}, presence: true

  default_scope { where(ignored: false) }
  scope :including_ignored, -> { unscope(where: :ignored) }

  scope :visible, ->(settings) {
    enabled = DEFAULT_SEVERITIES.merge(settings.symbolize_keys).select { |cat, sev| sev.to_sym != :silent }
    where(category: enabled.keys)
  }

  broadcasts_refreshes

  CATEGORIES = [
    :missing,
    :empty,
    :destination_exists, # No longer used, but kept for compatibility
    :nesting,
    :inefficient,
    :duplicate,
    :no_image,
    :no_3d_model,
    :non_manifold,
    :inside_out,
    :no_license,
    :no_links,
    :no_creator,
    :no_tags,
    :http_error
  ]
  enum :category, CATEGORIES

  SEVERITIES = [
    :silent,
    :info,
    :warning,
    :danger
  ]

  DEFAULT_SEVERITIES = ActiveSupport::HashWithIndifferentAccess.new(
    missing: :danger,
    empty: :info,
    nesting: :warning,
    inefficient: :info,
    duplicate: :warning,
    no_image: :silent,
    no_3d_model: :silent,
    non_manifold: :warning,
    inside_out: :warning,
    no_license: :silent,
    no_links: :silent,
    no_creator: :silent,
    no_tags: :silent,
    http_error: :info
  )

  ICONS = ActiveSupport::HashWithIndifferentAccess.new(
    missing: "question-mark-circle",
    nesting: "files-alt",
    duplicate: "files",
    inefficient: "file-earmark-zip",
    no_image: "file-earmark-image",
    no_creator: "person-x",
    no_tags: "label",
    http_error: "question-mark-circle"
  )

  def self.create_or_clear(problematic, category, should_exist, options = {})
    if should_exist
      problematic.problems.find_or_create_by(options.merge(category: category))
    else
      problematic.problems.where(category: category).destroy_all
    end
    should_exist
  end

  def self.ransackable_attributes(auth_object = nil)
    ["category", "created_at", "id", "public_id", "note", "problematic_id", "problematic_type", "updated_at", "ignored", "in_progress"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["problematic"]
  end

  def parent
    if problematic_type == "ModelFile"
      problematic.model
    elsif problematic_type == "Link"
      problematic.linkable
    end
  end

  def icon
    ICONS[category] || "fire"
  end

  RESOLUTIONS = {
    missing: :destroy,
    empty: :destroy,
    nesting: :merge,
    inefficient: :convert,
    duplicate: :destroy,
    no_image: :upload,
    no_3d_model: :upload,
    non_manifold: :show,
    inside_out: :show,
    no_license: :edit,
    no_links: :edit,
    no_creator: :edit,
    no_tags: :edit,
    http_error: :edit
  }

  def resolution_strategy
    RESOLUTIONS[category.to_sym] or raise NotImplementedError.new(category)
  end
end
