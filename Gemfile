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
# Use SCSS for stylesheets
# gem "sass-rails", ">= 6"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem "webpacker", "~> 5.0"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

gem "geokit-rails"

# Set CLOUDINARY_URL and other env variables
gem "dotenv-rails", groups: [:development, :test], require: "dotenv/rails-now"

# File upload
gem "cloudinary"
gem "carrierwave"
gem "carrierwave-base64"


# GraphQL queries
gem "graphql"
gem "graphql_devise"

# Send HTTP requests easily
gem "httparty"

# Admin backend
gem "administrate"

# CORS headers
gem "rack-cors"

# Store base64 images
gem "active_storage_base64"

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Searchable models
gem "search_cop"


group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails", "~> 5.0"
  gem "database_cleaner"
end

group :development do
  # Annotate with database schema
  gem "annotate"

  # Generate an ER diagram
  gem "railroady"
  gem "rails-erd"

  # VSCode ruby intellisense
  gem "solargraph"

  # Make it go fasterer!
  gem "fasterer"

  # Linting
  gem "rubocop"
  gem "rubocop-rails_config"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "rspec_junit_formatter"

  # Security
  gem "brakeman"
  gem "reek"

  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  gem "graphql-rails-generators", group: :development

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"
  gem "listen", "~> 3.3"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "graphiql-rails"
