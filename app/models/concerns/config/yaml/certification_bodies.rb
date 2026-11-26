module Config::Yaml::CertificationBodies
  extend ActiveSupport::Concern

  class_methods do
    # The certification bodies of every industry catalogue (config/industries/*/catalogue.yml) with their levels, each
    # tagged with the industry whose catalogue lists it
    #
    # @return [Hash{Symbol => Hash}] by slug
    def config
      @config ||= ::Industry.all.values.map do |industry|
        industry.catalogue.fetch("certification_bodies", {}).transform_values { |body| body.merge("industry" => industry.slug) }
      end.reduce({}, :merge).deep_symbolize_keys
    end
  end
end
