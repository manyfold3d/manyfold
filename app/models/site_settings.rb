# RailsSettings Model
class SiteSettings < RailsSettings::Base
  cache_prefix { "v1" }

  field :model_tags_filter_stop_words, type: :boolean, default: true
  field :model_tags_tag_model_directory_name, type: :boolean, default: false
  field :model_tags_stop_words_locale, type: :string, default: "en"
  field :model_tags_custom_stop_words, type: :array, default: SupportedMimeTypes.indexable_extensions
  field :model_tags_auto_tag_new, type: :string, default: "!new"
  field :model_path_template, type: :string, default: "{tags}/{modelName}{modelId}"
  field :parse_metadata_from_path, type: :boolean, default: true
  field :safe_folder_names, type: :boolean, default: true
  field :analyse_manifold, type: :boolean, default: false
  field :anonymous_usage_id, type: :string, default: nil
  field :default_viewer_role, type: :string, default: "member"

  def self.registration_enabled?
    Rails.application.config.manyfold_features[:registration]
  end

  def self.email_configured?
    !Rails.env.production? || ENV.fetch("SMTP_SERVER", false)
  end

  def self.max_file_upload_size
    ENV.fetch("MAX_FILE_UPLOAD_SIZE", 1_073_741_824).to_i
  end

  def self.max_file_extract_size
    ENV.fetch("MAX_FILE_EXTRACT_SIZE", 1_073_741_824).to_i
  end

  def self.demo_mode_enabled?
    Rails.application.config.manyfold_features[:demo_mode]
  end

  def self.multiuser_enabled?
    Rails.application.config.manyfold_features[:multiuser]
  end

  def self.federation_enabled?
    Rails.application.config.manyfold_features[:federation]
  end

  def self.oidc_enabled?
    Rails.application.config.manyfold_features[:oidc]
  end

  def self.default_user
    User.with_role(:administrator).first
  end

  def self.ignored_file?(pathname)
    @@patterns ||= [
      /^\.[^\.]+/, # Hidden files starting with .
      /.*\/@eaDir\/.*/, # Synology temp files
      /__MACOSX/ # MACOS resource forks
    ]
    (File.split(pathname) - ["."]).any? do |path_component|
      @@patterns.any? { |pattern| path_component =~ pattern }
    end
  end

  module UserDefaults
    RENDERER = ActiveSupport::HashWithIndifferentAccess.new(
      grid_width: 200,
      grid_depth: 200,
      show_grid: true,
      enable_pan_zoom: false,
      background_colour: "#000000",
      object_colour: "#cccccc",
      render_style: "normals"
    )

    PAGINATION = ActiveSupport::HashWithIndifferentAccess.new(
      models: true,
      creators: true,
      collections: true,
      per_page: 12
    )

    TAG_CLOUD = ActiveSupport::HashWithIndifferentAccess.new(
      threshold: 2,
      heatmap: true,
      keypair: true,
      sorting: "frequency"
    )

    FILE_LIST = ActiveSupport::HashWithIndifferentAccess.new(
      hide_presupported_versions: true
    )
  end
end
