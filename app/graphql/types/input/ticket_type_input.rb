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
      argument :is_tandem, Boolean, required: false
      argument :min_certification_rank, Int, required: false
      argument :required_qualification_id, Int, required: false

      argument :extra_ids, [Int], required: false
    end
  end
end
