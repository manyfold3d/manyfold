if Amiko.env.development?
  Amiko.application.config.after_initialize do
    require "i18n-js/listen"
    I18nJS.listen(
      config_file: Amiko.root.join("config/i18n-js.yml")
    )
  end
end
