class Types::Dropzone::Settings < Types::Base::Object
  field :require_rig_inspection, Boolean, null: true,
        description: 'Whether or not rig inspections are required before manifesting a jump'
  field :require_license, Boolean, null: true,
        description: 'Should a valid license be required to manifest a jump?'
  field :require_credits, Boolean, null: true,
        description: 'When this is enabled, users cannot manifest if they have no credits'
  field :require_membership, Boolean, null: true,
        description: 'When this is enabled, users cannot manifest if their membership is out of date'
  field :allow_negative_credits, Boolean, null: true,
        description: 'When this is enabled, users can manifest even if they go into negatives'
  field :allow_manifest_bypass, Boolean, null: true,
        description: 'Allow manifest to bypass all rules?'
  field :allow_double_manifesting, Boolean, null: true,
        description: 'Allow users to double-manifest'
end