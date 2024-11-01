source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.1.5"
# Use Puma as the app server
gem "puma", "~> 6.4"
# Deliver assets with Propshaft
gem "propshaft", "~> 1.1"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
gem "cssbundling-rails", "~> 1.4"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.13"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.3"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

gem "dotenv-rails", "~> 3.1", group: :development
gem "acts-as-taggable-on", "~> 11.0"

gem "ffi-libarchive", "~> 1.1"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Database adapters
gem "activerecord-enhancedsqlite3-adapter", "~> 0.8.0"
group :production do
  gem "mysql2", "~> 0.5.6"
  gem "pg", "~> 1.5"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "standard", "~> 1.41.1"
  gem "factory_bot"
  gem "faker", "~> 3.5"
  gem "guard", "~> 2.19"
  gem "guard-rspec", "~> 4.7"
  gem "database_cleaner-active_record", "~> 2.2"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-i18n", require: false
  gem "rubocop-performance", "~> 1.21", require: false
  gem "rubyzip", "~> 2.3"
  gem "i18n-tasks", "~> 1.0"
  gem "simplecov", "~> 0.22.0", require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  gem "scout_apm"
  gem "listen", "~> 3.9"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "cocooned", "~> 2.4"

gem "public_suffix", "~> 6.0"

gem "activerecord-nulldb-adapter", "~> 1.0.1"

gem "memoist", "~> 0.16.2"
gem "stopwords-filter2", require: "stopwords"

gem "devise", "~> 4.9"
gem "devise-i18n", "~> 1.12"

gem "data_migrate", "11.1.0"

gem "rails-settings-cached", "~> 2.9"
gem "activeadmin", "~> 3.2"

gem "kaminari", "~> 1.2"

gem "lograge", "~> 0.14.0"

gem "acts_as_favoritor", "~> 6.0"

gem "sqlite3_ar_regexp", github: "manyfold3d/sqlite3_ar_regexp", ref: "rails-7.1-support"

gem "mittsu", github: "manyfold3d/mittsu", ref: "manyfold"

gem "view_component", "~> 3.20"

gem "rails-controller-testing", "~> 1.0", group: :test

gem "pundit", "~> 2.4"

gem "spdx", "~> 4.1"
gem "rack-contrib", "~> 2.5"

gem "rails-i18n", "~> 7.0"

gem "erb_lint", "~> 0.7.0", group: :development, require: false

gem "i18n-js", "~> 4.2"

gem "translation", "~> 1.41", group: :development

gem "string-similarity", "~> 2.1"

gem "rolify", "~> 6.0"

gem "letter_opener", "~> 1.10", group: :development

gem "sidekiq", "~> 7.3"

gem "sidekiq-failures", "~> 1.0"
gem "activejob-status", "~> 1.0"

gem "brakeman", "~> 6.2"

gem "i18n_data", "~> 1.1.0"
gem "bullet", "~> 7.2", group: :development

gem "logstash-event", "~> 1.2"

gem "climate_control", "~> 1.2", group: :test

gem "sys-filesystem", "~> 1.5"
gem "shrine", "~> 3.6"

gem "aws-sdk-s3", "~> 1.169"

gem "better_content_security_policy", "~> 0.1.4"

gem "devise_zxcvbn", "~> 6.0"

gem "ransack", "~> 4.2"
gem "federails", git: "https://gitlab.com/experimentslabs/federails.git", branch: "main"
gem "caber"

gem "nanoid", "~> 2.0"

gem "kramdown", "~> 2.4"

gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth_openid_connect", "~> 0.8.0"

gem "sidekiq-cron", "~> 1.12"

gem "rails_performance", "~> 1.2", group: [:development, :production]

gem "pghero", "~> 3.6"
gem "pg_query", "~> 5.1"

gem "get_process_mem", "~> 1.0"
