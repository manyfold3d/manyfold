if Rails.env.development?
  TranslationIO.configure do |config|
    config.api_key = ENV["TRANSLATION_IO_API_KEY"]
    config.disable_gettext = true
    config.ignored_key_prefixes = [
      # No ActiveAdmin for now, too much cruft
      "active_admin",
      "activerecord.attributes.active_admin",
      "formtastic",
      "ransack",
      # Other things we don't want to translate or don't know what they are
      "i18n_tasks",
      "number",
      "errors",
      "flash",
      "helpers.page_entries_info"
    ]
    config.source_locale = "en"
    config.target_locales = ["ru", "es", "fr", "de"]
  end
end
