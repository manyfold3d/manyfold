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
end
