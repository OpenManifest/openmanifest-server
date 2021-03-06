# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 6.1.3", ">= 6.1.3.1"

# Heroku database
gem "pg"

# Use Puma as the app server
gem "puma", "~> 5.0"
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Coordinate based location
gem "geokit-rails"

# Set CLOUDINARY_URL and other env variables
gem "dotenv-rails", groups: %i[development test], require: "dotenv/rails-now"

# Soft delete records
gem "discard", "~> 1.2"

# File upload
gem "carrierwave"
gem "carrierwave-base64"
gem "cloudinary"

# GraphQL queries
gem "graphql", "~> 1.12.21"
gem "graphql_devise", "~> 0.17.1"

# Send HTTP requests easily
gem "httparty"

# Admin backend
gem "administrate"

# CORS headers
gem "rack-cors"

# Store base64 images
gem "active_storage_base64"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Searchable models
gem "search_cop"

# Separate business logic
gem "active_interaction", "~> 4.0.0"
gem "active_interaction-extras"

# Count things
gem "counter_culture"

gem "sentry-ruby"
gem "sentry-rails"
gem "state_machines-activerecord"

# Manage state transitions
gem "state_machines"

# Apple login
gem "jwt"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "faker"
  gem "guard"
  gem "guard-rspec"
  gem "pry"
  gem "awesome_print"
  gem "rspec-json_expectations"

  gem "database_cleaner"
  gem "rspec-rails", "~> 5.0"
end

group :development do
  # Annotate with database schema
  gem "annotate"

  # Generate an ER diagram
  gem "railroady"
  gem "rails-erd"

  # VSCode ruby intellisense
  gem "solargraph"
  gem "yard", "0.9.24"

  # Make it go fasterer!
  gem "fasterer"

  # Linting
  gem "rspec_junit_formatter"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rails_config"
  gem "rubocop-rspec"

  # Security
  gem "brakeman"
  gem "reek"

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "graphql-rails-generators", group: :development
  gem "web-console", ">= 4.1.0"

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

group :test do
  gem "webmock"
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "graphiql-rails"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
