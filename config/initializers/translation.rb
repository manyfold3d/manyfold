if Rails.env.development?
  TranslationIO.configure do |config|
    config.api_key = ENV["TRANSLATION_IO_API_KEY"]
    config.disable_gettext = true
    config.ignored_key_prefixes = [
      "activerecord.models.comment",
      "activerecord.errors.messages.record_invalid",
      "activerecord.errors.messages.restrict_dependent_destroy",
      "formtastic",
      # Other things we don't want to translate or don't know what they are
      "i18n_tasks",
      "number",
      "errors",
      "flash",
      "helpers.page_entries_info",
      "datetime",
      "date",
      "time",
      "helpers"
    ]
    config.source_locale = "en"
    config.target_locales = YAML.load_file(Rails.root.join("config/locales.yml")).values.flatten.without(config.source_locale)
  end
end
