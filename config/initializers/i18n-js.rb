if Mosscap.env.development?
  Mosscap.application.config.after_initialize do
    require "i18n-js/listen"
    I18nJS.listen(
      config_file: Mosscap.root.join("config/i18n-js.yml")
    )
  end
end
