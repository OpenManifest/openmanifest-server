# frozen_string_literal: true

module Types::Manifest
  # The member's part of it, for a pick list or a checklist
  class MembershipEligibility < Types::Base::Object
    description "Whether a member is ready to manifest, rule by rule"

    field :ready, Boolean, null: false, description: "Every rule that applies passes"
    field :rules, [Types::Manifest::EligibilityResult], null: false
  end
end
