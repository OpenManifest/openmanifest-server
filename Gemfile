# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.11"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.2.4"

# Heroku database
gem "pg"

# Use Puma as the app server
gem "puma", "~> 6.0"
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Coordinate based location
gem "geokit-rails"
gem 'rexml'
gem "dotenv-rails", groups: %i(development test), require: "dotenv/rails-now"

# Soft delete records
gem "discard", "~> 1.2"

# Multiprocess serving
gem "foreman"

# GraphQL queries
gem "graphql", "~> 2.4.18"
gem "graphql_devise", "~> 2.0.0"

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

# Count things. Pinned: counter_culture 3.14.0 keeps the in-memory counter current inside a group manifest, which
# exposes the double counting of BUG-019 (three tandem jumpers fail with "No slots available"). P6.10 fixes BUG-019 and
# removes this pin.
gem "counter_culture", "3.3.0"

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
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i(mri windows)
  gem "factory_bot_rails"
  gem "rspec-json_expectations"

  gem "database_cleaner"
  gem "rspec-rails", "~> 7.1.1"
  gem "parallel_tests"
  gem "rspec_junit_formatter"
end

group :development do
  # Annotate with database schema
  gem "annotate"

  gem "web-console", ">= 4.1.0"

  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-performance"
  gem "rubocop-graphql"
  gem "rubocop-rspec"

  # Security
  gem "brakeman"

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "graphql-rails-generators", group: :development

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

group :test do
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "graphiql-rails"
gem "tzinfo-data", platforms: %i(windows jruby)
