class Problem < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.problem")

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
    :missing, # i18n-tasks-use t("problems.model.missing.title") t("problems.model.missing.description_html") t("problems.model_file.missing.title") t("problems.model_file.missing.description_html")
    :empty, # i18n-tasks-use t("problems.model.empty.title") t("problems.model.empty.description_html") t("problems.model_file.empty.title") t("problems.model_file.empty.description_html")
    :destination_exists, # No longer used, but kept for compatibility
    :nesting, # i18n-tasks-use t("problems.model.nesting.title") t("problems.model.nesting.description_html")
    :inefficient, # i18n-tasks-use t("problems.model_file.inefficient.title") t("problems.model_file.inefficient.description_html")
    :duplicate, # i18n-tasks-use t("problems.model_file.duplicate.title") t("problems.model_file.duplicate.description_html")
    :no_image, # i18n-tasks-use t("problems.model.no_image.title") t("problems.model.no_image.description_html")
    :no_3d_model, # i18n-tasks-use t("problems.model.no_3d_model.title") t("problems.model.no_3d_model.description_html")
    :non_manifold, # i18n-tasks-use t("problems.model_file.non_manifold.title") t("problems.model_file.non_manifold.description_html")
    :inside_out, # i18n-tasks-use t("problems.model_file.inside_out.title") t("problems.model_file.inside_out.description_html")
    :no_license, # i18n-tasks-use t("problems.model.no_license.title") t("problems.model.no_license.description_html")
    :no_links, # i18n-tasks-use t("problems.model.no_links.title") t("problems.model.no_links.description_html")
    :no_creator, # i18n-tasks-use t("problems.model.no_creator.title") t("problems.model.no_creator.description_html")
    :no_tags, # i18n-tasks-use t("problems.model.no_tags.title") t("problems.model.no_tags.description_html")
    :http_error, # i18n-tasks-use t("problems.link.http_error.title") t("problems.link.http_error.description")
    :file_naming # i18n-tasks-use t("problems.model.file_naming.title") t("problems.model.file_naming.description_html")
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
    http_error: :info,
    file_naming: :warning
  )

  ICONS = ActiveSupport::HashWithIndifferentAccess.new(
    missing: "question-mark-circle",
    nesting: "files-alt",
    duplicate: "files",
    inefficient: "file-earmark-zip",
    no_image: "file-earmark-image",
    no_creator: "person-x",
    no_tags: "label",
    http_error: "question-mark-circle",
    file_naming: "folder-cross"
  )

  def self.create_or_clear(problematic, category, should_exist, options = {})
    if should_exist
      problematic.problems.where(category: category).first_or_create.update(options)
    else
      problematic.problems.where(category: category).destroy_all
    end
    should_exist
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
    http_error: :edit,
    file_naming: :organize
  }

  def resolution_strategy
    RESOLUTIONS[category.to_sym] or raise NotImplementedError.new(category)
  end
end
