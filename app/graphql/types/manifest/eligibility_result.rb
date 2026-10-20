# frozen_string_literal: true

module Types::Manifest
  # What one rule says about a person on a slot (P7.16): the client shows these, it does not re-implement the rules
  class EligibilityResult < Types::Base::Object
    description "What one eligibility rule says"

    field :code, String, null: false, description: "The rule: capacity, membership, credits, double_manifest, activity, certification, equipment, equipment_inspection, equipment_service, age, body_mass, group, payload, escort"
    field :ok, Boolean, null: false
    field :status, String, null: false, description: "PASS, EXPIRING (within 14 days), FAIL or NOT_REQUIRED"
    field :message, String, null: true, description: "Why it fails"
    field :problem, String, null: true, description: "A more precise code when it fails, e.g. date_of_birth_missing, escort_capacity"
    field :bypassed, Boolean, null: false, method: :bypassed?, description: "A failure the manifester may let through (they hold the permission and the operator allows it)"
    field :expires_at, Int, null: true
    def expires_at
      object.expires_at&.to_i
    end
    field :amount_cents, Int, null: true
  end
end
