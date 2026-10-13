module Operators
  module Configuration
    extend ActiveSupport::Concern

    included do
      default_settings.each do |key, value|
        method_name = key.to_s
        method_name += "?" if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        define_method(method_name) { settings[key.to_s] }
      end

      # Set up default settings for an operator when initialized: the neutral ones, then the starting values of the
      # operator's industry template, then what the operator has set
      after_initialize do
        # Partial selects (counter_culture's reconciliation) do not load the column
        next unless has_attribute?(:settings)

        template_settings = has_attribute?(:industry) && industry.present? ? Industry.fetch(industry).settings.symbolize_keys : {}
        defaults = self.class.default_settings.merge(template_settings)
        next if defaults.keys.all? { |key| settings.key?(key.to_s) }
        assign_attributes(settings: defaults.merge((settings || {}).symbolize_keys))
      end

      def settings=(new_settings)
        current_settings = self.class.default_settings.stringify_keys.merge(settings || {})
        super(current_settings.merge(new_settings.transform_keys(&:to_s)))
      end
    end

    class_methods do
      # Set up default settings for an operator
      #
      # @return [Hash]
      def default_settings
        {
          # User must have a rig with a valid inspection to manifest?
          require_rig_inspection: true,
          # User must have a valid certification to manifest?
          require_certification: true,
          # User must have credits to manifest?
          require_credits: true,
          # Users membership must be valid?
          require_membership: true,
          # Users can go into negative credits?
          allow_negative_credits: false,
          # Allow manifest to bypass all rules?
          allow_manifest_bypass: false,
          # Allow double-manifesting?
          allow_double_manifesting: false,
          # Allow manifesting without equipment?
          require_equipment: true,

          # Allow manifesting without reserve in date?
          require_reserve_in_date: true,
          # Members may manifest themselves; when false, only staff with the ...User... slot permissions manifest
          allow_self_manifest: true,
        }
      end
    end
  end
end
