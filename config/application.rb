# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "sprockets/railtie"
require 'action_cable/engine'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dz
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Background jobs run on Solid Queue (tables in the primary database); the test environment only records them
    config.active_job.queue_adapter = :solid_queue

    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
