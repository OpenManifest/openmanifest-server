module Config::Yaml::ActivityTypes
  extend ActiveSupport::Concern

  class_methods do
    # The activity types of every industry catalogue (config/industries/*/catalogue.yml), once each
    #
    # @return [Array<Hash{Symbol => String}>] name and slug
    def config
      @config ||= ::Industry.all.values.flat_map { |industry| industry.catalogue.fetch("activity_types", []) }.
        map(&:symbolize_keys).uniq { |activity_type| activity_type[:slug] }
    end
  end
end
