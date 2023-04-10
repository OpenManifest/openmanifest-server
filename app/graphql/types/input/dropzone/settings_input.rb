class Types::Input::Dropzone::SettingsInput < Types::Base::Input
  argument :require_rig_inspection, Boolean, required: false,
                                             description: 'Whether or not rig inspections are required before manifesting a jump'
  argument :require_license, Boolean, required: false,
                                      description: 'Should a valid license be required to manifest a jump?'
  argument :require_credits, Boolean, required: false,
                                      description: 'When this is enabled, users cannot manifest if they have no credits'
  argument :require_membership, Boolean, required: false,
                                         description: 'When this is enabled, users cannot manifest if their membership is out of date'
  argument :allow_negative_credits, Boolean, required: false,
                                             description: 'When this is enabled, users can manifest even if they go into negatives'
  argument :allow_manifest_bypass, Boolean, required: false,
                                            description: 'Allow manifest to bypass all rules?'

  argument :require_reserve_in_date, Boolean, required: false,
           description: 'When this is enabled, users cannot manifest if their reserve is out of date'
  argument :require_equipment, Boolean, required: false,
           description: 'When this is enabled, users cannot manifest if they have no equipment'
  argument :allow_double_manifesting, Boolean, required: false,
           description: 'Allow users to double-manifest'
end
