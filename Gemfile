# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.7"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 8.1.4"

# Heroku database
gem "pg"

# Use Puma as the app server
gem "puma"
gem "redis"
# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Coordinate based location
gem "geokit-rails"
gem 'rexml'
gem "dotenv-rails", groups: %i(development test), require: "dotenv/load"

# Soft delete records
gem "discard"

# Multiprocess serving
gem "foreman"

# GraphQL queries
gem "graphql", "~> 2.6.11"
gem "graphql_devise", "~> 2.4.0"

# Send HTTP requests easily
gem "httparty"

# CORS headers
gem "rack-cors"

# Store base64 images
gem "active_storage_base64"
gem "google-cloud-storage"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Searchable models
gem "search_cop"

# Separate business logic
gem "active_interaction"
gem "active_interaction-extras"

# Count things
gem "counter_culture"

# Background jobs, in the primary database
gem "solid_queue", "~> 1.7"

# Debugging
gem "appsignal"

# Manage state transitions
gem "state_machines-activerecord"
gem "state_machines"

# Apple login
gem "jwt"

gem "sprockets"
# The rails gem stopped depending on sprockets-rails in 7.0.5; config/application.rb and the environments still use it
gem "sprockets-rails"

# Bulk import
gem "activerecord-import"

# Find models by global ID
gem "globalid"

gem "faker"

gem "pry"
gem "awesome_print"

gem 'image_processing'

group :development, :test do
  # Call `debugger` anywhere in the code to stop execution and get a debugger console
  gem "debug", platforms: %i(mri windows), require: "debug/prelude"
  gem "factory_bot_rails"
  gem "rspec-json_expectations"

  gem "database_cleaner"
  gem "rspec-rails", "~> 8.0.4"
  gem "parallel_tests"
  gem "rspec_junit_formatter"
end

group :development do
  # Annotate with database schema
  gem "annotaterb"

  gem "web-console", ">= 4.1.0"

  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-performance"
  gem "rubocop-graphql"
  gem "rubocop-rspec"
  gem "rubocop-factory_bot"

  # Security
  gem "brakeman"

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "graphql-rails-generators", group: :development

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "listen"
  gem "rack-mini-profiler"
end

group :test do
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "graphiql-rails"
gem "tzinfo-data", platforms: %i(windows jruby)
