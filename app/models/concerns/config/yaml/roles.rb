module Config::Yaml::Roles
  extend ActiveSupport::Concern

  class_methods do
    # Parse YAML config for default configuration
    #
    # @return [Hash<Symbol, Array<String>>]
    def config
      @config ||= YAML.safe_load(
        File.read("config/seed/access.yml"),
        symbolize_names: true,
        aliases: true
      )[:roles]
    end

    # Get all default role slugs
    #
    # @return [Hash<Symbol, Array<String>>]
    def slugs
      config.keys
    end
  end

  included do
    # Get all default permissions for a given
    # role once its been initialized
    #
    # @return [Array<String>]
    def yaml_permission_slugs
      self.class.config[name.to_sym] || []
    end
  end
end
