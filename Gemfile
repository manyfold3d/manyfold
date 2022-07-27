source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.1.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.0.3"
# Use Puma as the app server
gem "puma", "~> 5.6"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 5.4"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.11"
# Use Redis adapter to run Action Cable in production
gem "stimulus_reflex", "~> 3.4"
gem "redis", ">= 4.0", require: ["redis", "redis/connection/hiredis"]
gem "hiredis"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

gem "dotenv-rails", "~> 2.8"
gem "acts-as-taggable-on", "~> 9.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :production do
  gem "pg", "~> 1.4"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "sqlite3", "~> 1.4"
  gem "rspec-rails"
  gem "standard", "~> 1.14.0"
  gem "factory_bot"
  gem "faker", "~> 2.21"
  gem "guard", "~> 2.18"
  gem "guard-rspec", "~> 4.7"
  gem "database_cleaner-active_record", "~> 2.0"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 3.0"
  gem "listen", "~> 3.7"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "cocoon", "~> 1.2"

gem "public_suffix", "~> 5.0"

gem "delayed_job_active_record", "~> 4.1"

gem "activerecord-nulldb-adapter", "~> 0.8.0"

gem "memoist", "~> 0.16.2"
gem "stopwords-filter", require: "stopwords"

gem "devise", "~> 4.8"

gem "data_migrate", "~> 8.0"

gem "rails-settings-cached", "~> 2.8"
gem "activeadmin", "~> 2.13"

gem "kaminari", "~> 1.2"

gem "lograge", "~> 0.12.0"
