module Config::Yaml::JumpTypes
  extend ActiveSupport::Concern

  class_methods do
    # Parse YAML config for default configuration
    #
    # @return [Hash<Symbol, Array<String>>]
    def config
      @config ||= YAML.safe_load(
        File.read("config/seed/global.yml"),
        symbolize_names: true
      )[:jump_types]
    end
  end
end
