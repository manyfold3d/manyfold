if Rails.env.development?
  TranslationIO.configure do |config|
    config.api_key = ENV["TRANSLATION_IO_API_KEY"]
    config.disable_gettext = true
    config.ignored_key_prefixes = [
      "errors" # built-in errors that get picked up
    ]
    config.source_locale = "en"
    config.target_locales = ["de"]
  end
end
