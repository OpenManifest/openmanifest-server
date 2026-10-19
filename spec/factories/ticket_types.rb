# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_types
#
#  id                     :bigint           not null, primary key
#  currency               :string
#  name                   :string
#  operator_id            :bigint           not null
#  default_destination_id :bigint
#  allow_manifesting_self :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  requires_escort        :boolean          default(FALSE)
#
FactoryBot.define do
  factory :ticket_type do
    operator
    name { ["Height", "Hop n Pop", "Boogie"].sample }
    initialize_with { TicketType.find_or_initialize_by(name: name, operator: operator) }
    cost { Faker::Number.between(from: 25, to: 60) }
    currency { "AUD" }
    # The ticket's own height, for the operators whose slots go to an altitude
    default_destination do
      feet = name == "Hop n Pop" ? 4000 : 14_000
      Destination.altitude_for(operator, feet) if operator.destinations_per_slot?
    end
    allow_manifesting_self { true }
  end
end
