# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_types
#
#  id                     :bigint           not null, primary key
#  cost                   :float
#  currency               :string
#  name                   :string
#  dropzone_id            :bigint           not null
#  altitude               :integer
#  allow_manifesting_self :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  is_tandem              :boolean          default(FALSE)
#  is_deleted             :boolean          default(FALSE)
#
FactoryBot.define do
  factory :ticket_type do
    dropzone
    name { ["Height", "Hop n Pop", "Boogie"].sample }
    initialize_with { TicketType.find_or_initialize_by(name: name, dropzone: dropzone) }
    cost { Faker::Number.between(from: 25, to: 60) }
    currency { "AUD" }
    altitude do
      case name
      when "Height"
      when "Boogie"
        14_000
      when "Hop n Pop"
        4000
      else
        14_000
      end
    end
    allow_manifesting_self { true }
  end
end
