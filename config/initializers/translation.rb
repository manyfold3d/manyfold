if Rails.env.development?
  TranslationIO.configure do |config|
    config.api_key = ENV["TRANSLATION_IO_API_KEY"]
    config.source_locale = "en"
    config.target_locales = ["de"]
  end
end
