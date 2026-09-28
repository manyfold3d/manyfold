RSpec.configure do |config|
  config.before(:suite) do
    I18nJS.call(config_file: Mosscap.root.join("config/i18n-js.yml"))
  end
end
