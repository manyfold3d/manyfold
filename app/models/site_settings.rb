# RailsSettings Model
class SiteSettings < RailsSettings::Base
  cache_prefix { "v1" }

  field :model_tags_filter_stop_words, type: :boolean, default: true
  field :model_tags_tag_model_directory_name, type: :boolean, default: false
  field :model_tags_stop_words_locale, type: :string, default: "en"
  field :model_tags_custom_stop_words, type: :array, default: (SupportedMimeTypes.image_extensions + SupportedMimeTypes.model_extensions)
  field :model_tags_auto_tag_new, type: :string, default: "!new"
  field :model_path_template, type: :string, default: "{tags}/{modelName}{modelId}"
  field :parse_metadata_from_path, type: :boolean, default: true
  field :safe_folder_names, type: :boolean, default: true
  field :analyse_manifold, type: :boolean, default: false
  field :anonymous_usage_id, type: :string, default: nil

  def self.registration_enabled
    ENV.fetch("REGISTRATION", false) == "enabled"
  end

  def self.email_configured
    !Rails.env.production? || ENV.fetch("SMTP_SERVER", false)
  end

  def self.max_file_upload_size
    ENV.fetch("MAX_FILE_UPLOAD_SIZE", 1_073_741_824).to_i
  end

  def self.max_file_extract_size
    ENV.fetch("MAX_FILE_EXTRACT_SIZE", 1_073_741_824).to_i
  end

  module UserDefaults
    RENDERER = {
      grid_width: 200,
      grid_depth: 200,
      show_grid: true,
      enable_pan_zoom: false,
      background_colour: "#000000",
      object_colour: "#cccccc",
      render_style: "normals"
    }

    PAGINATION = {
      models: true,
      creators: true,
      per_page: 12
    }

    TAG_CLOUD = {
      threshold: 0,
      heatmap: true,
      keypair: true,
      sorting: "frequency",
      hide_unrelated: true
    }

    FILE_LIST = {
      hide_presupported_versions: true
    }
  end
end
