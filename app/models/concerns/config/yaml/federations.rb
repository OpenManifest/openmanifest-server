module Config::Yaml::Federations
  extend ActiveSupport::Concern

  class_methods do
    # The certification bodies of every industry catalogue (config/industries/*/catalogue.yml) with their levels
    #
    # @return [Hash{Symbol => Hash}] by slug
    def config
      @config ||= ::Industry.all.values.map { |industry| industry.catalogue.fetch("federations", {}) }.
        reduce({}, :merge).deep_symbolize_keys
    end
  end
end
