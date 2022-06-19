# RailsSettings Model
class SiteSettings < RailsSettings::Base
  cache_prefix { "v1" }

  field :model_tags_filter_stop_words, type: :boolean, default: true
  field :model_tags_stop_words_locale, type: :string, default: "en"
  field :model_tags_custom_stop_words, type: :array, default: Rails.configuration.formats.flatten(2).select { |x| x.is_a?(String) }
end
