# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  capacity               :integer
#  min_capacity           :integer
#  kind                   :string           not null
#  hours                  :integer
#  next_maintenance_hours :integer
#  registration           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  operator_id            :bigint           not null
#
FactoryBot.define do
  factory :vehicle do
    operator { nil }
    name { Faker::Color.color_name }
    registration { Faker::Name.first_name }
    capacity { Faker::Number.between(from: 4, to: 20) }

    factory :vehicle_with_loads do
      transient do
        load_count { 3 }
      end

      after(:create) do |vehicle, evaluator|
        create_list(:load, evaluator.load_count, vehicle: vehicle, gca: vehicle.operator.memberships.first,
                                                 pilot: vehicle.operator.memberships.first)

        vehicle.reload
      end
    end
  end
end
