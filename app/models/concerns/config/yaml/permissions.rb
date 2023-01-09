module Config::Yaml::Permissions
  extend ActiveSupport::Concern

  class_methods do
    # Gets all default acting permissions
    #
    # @return [Array<String>]
    def default_acting
      @default_acting ||= config[:acting].map(&:to_sym)
    end

    # Gets all default CRUD permissions (non-acting, e.g not actAsPilot)
    #
    # @return [Array<String>]
    def default_crud
      @default_crud ||= config[:crud].values.flatten.uniq.map(&:to_sym)
    end

    # Gets all default permissions
    #
    # @return [Array<String>]
    def slugs
      Permission.default_acting + Permission.default_crud
    end

    # Parse the YAML config for permissions
    #
    # @return [Hash<Symbol, Array<String>>]
    def config
      @config ||= YAML.safe_load(
        File.read("config/seed/access.yml"),
        symbolize_names: true,
        aliases: true
      )[:permissions]
    end
  end
end
