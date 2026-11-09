class Types::Input::Operator::SettingsInput < Types::Base::Input
  argument :require_equipment_inspection, Boolean, required: false,
                                                   description: 'Whether or not equipment inspections are required before manifesting a jump'
  argument :require_certification, Boolean, required: false,
                                            description: 'Should a valid certification be required to manifest a jump?'
  argument :require_credits, Boolean, required: false,
                                      description: 'When this is enabled, users cannot manifest if they have no credits'
  argument :require_membership, Boolean, required: false,
                                         description: 'When this is enabled, users cannot manifest if their membership is out of date'
  argument :allow_negative_credits, Boolean, required: false,
                                             description: 'When this is enabled, users can manifest even if they go into negatives'
  argument :allow_manifest_bypass, Boolean, required: false,
                                            description: 'Allow manifest to bypass all rules?'

  argument :require_equipment_in_service, Boolean, required: false,
                                                   description: 'When this is enabled, users cannot manifest if their reserve is out of date'
  argument :require_equipment, Boolean, required: false,
                                        description: 'When this is enabled, users cannot manifest if they have no equipment'
  argument :allow_double_manifesting, Boolean, required: false,
                                               description: 'Allow users to double-manifest'
  argument :call_schedule_minutes, [Int], required: false,
                                          description: 'Minutes before departure at which a boarding call is offered, longest first (up to six); none: loads depart directly'
  argument :units, GraphQL::Types::JSON, required: false,
                                         description: 'The units shown: { altitude: "ft" | "m", depth, distance: "km" | "nmi" | "mi" | "m", mass: "kg" | "lb", speed: "kn" | "kmh" | "mph", temperature: "c" | "f" }'
  argument :allow_self_manifest, Boolean, required: false,
                                          description: 'When this is disabled, only manifest staff can add, move or remove people on loads'
end
