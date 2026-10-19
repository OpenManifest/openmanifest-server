# frozen_string_literal: true

module Types
  module Input
    class TicketTypeInput < Types::Base::Input
      argument :currency, String, required: false
      money_argument :cost
      argument :name, String, required: false
      argument :default_destination_id, Int, required: false
      argument :allow_manifesting_self, Boolean, required: false
      argument :operator_id, Int, required: false
      argument :requires_escort, Boolean, required: false, description: "A slot takes guests who ride with its member, the escort (skydiving: tandem)"
      argument :escort_capacity, Int, required: false, description: "The most guests for each escort"
      argument :escort_qualification_id, Int, required: false, description: "The qualification the escort must hold"
      argument :escort_crew_role_id, Int, required: false, description: "The crew role whose permission the escort must have"
      argument :min_certification_rank, Int, required: false
      argument :required_qualification_id, Int, required: false

      argument :extra_ids, [Int], required: false
    end
  end
end
