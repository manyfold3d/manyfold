source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.2.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.0.8"
# Use Puma as the app server
gem "puma", "~> 6.4"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
gem "cssbundling-rails", "~> 1.3"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.11"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

gem "dotenv-rails", "~> 2.8"
gem "acts-as-taggable-on", "~> 10.0"

gem "ffi-libarchive", "~> 1.1"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :production do
  gem "pg", "~> 1.5"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "sqlite3", "~> 1.6"
  gem "rspec-rails"
  gem "standard", "~> 1.32.1"
  gem "factory_bot"
  gem "faker", "~> 3.2"
  gem "guard", "~> 2.18"
  gem "guard-rspec", "~> 4.7"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-i18n", require: false
  gem "rubocop-performance", "~> 1.19", require: false
  gem "i18n-tasks", "~> 1.0"
  gem "simplecov", "~> 0.22.0", require: false
  gem "sys-filesystem", "~> 1.4"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  # gem "rack-mini-profiler", "~> 3.1"
  gem "listen", "~> 3.8"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "cocoon", "~> 1.2"

gem "public_suffix", "~> 5.0"

gem "delayed_job_active_record", "~> 4.1"

gem "activerecord-nulldb-adapter", "~> 1.0.1"

gem "memoist", "~> 0.16.2"
gem "stopwords-filter2", require: "stopwords"

gem "devise", "~> 4.9"

gem "data_migrate", github: "Floppy/data-migrate", ref: "db-prepare-withdata"

gem "rails-settings-cached", "~> 2.9"
gem "activeadmin", "~> 3.1"

gem "kaminari", "~> 1.2"

gem "lograge", "~> 0.14.0"

gem "acts_as_favoritor", "~> 6.0"

gem "sqlite3_ar_regexp", "~> 2.2"

gem "mittsu", github: "danini-the-panini/mittsu", ref: "7f44c46"

gem "view_component", "~> 3.8"
