source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.1.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.3", ">= 7.0.3.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.6"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0", require: ["redis", "redis/connection/hiredis"]
gem "hiredis"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "dotenv-rails", "~> 2.7"
gem "acts-as-taggable-on", "~> 9.0"
gem "cocoon", "~> 1.2"
gem "public_suffix", "~> 4.0"
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
gem "bootstrap", "~> 5.2.0"

group :production do
  gem "pg", "~> 1.4"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails"
  gem "standard", "~> 1.13.0"
  gem "factory_bot"
  gem "faker", "~> 2.21"
  gem "guard", "~> 2.18"
  gem "guard-rspec", "~> 4.7"
  gem "database_cleaner-active_record", "~> 2.0"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
