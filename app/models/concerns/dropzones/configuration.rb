module Dropzones
  module Configuration
    extend ActiveSupport::Concern

    included do
      default_settings.each do |key, value|
        method_name = key.to_s
        method_name += "?" if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        define_method(method_name) { settings[key.to_s] }
      end

      # Set up default settings for a dropzone when initialized
      after_initialize do
        next if self.class.default_settings.keys.all? { |key| settings.key?(key) }
        assign_attributes(settings: self.class.default_settings.merge(settings || {}))
      end

      def settings=(new_settings)
        current_settings = self.class.default_settings.merge(settings || {})
        super(current_settings.merge(new_settings.transform_keys(&:to_s)))
      end
    end

    class_methods do
      # Set up default settings for a dropzone
      #
      # @return [Hash]
      def default_settings
        {
          # User must have a rig with a valid inspection to manifest?
          require_rig_inspection: true,
          # User must have a valid license to manifest?
          require_license: true,
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
        }
      end
    end
  end
end
