RSpec.configure do |config|
  config.before(:suite) do
    I18nJS.call(config_file: Rails.root.join("config/i18n-js.yml"))
  end
end
