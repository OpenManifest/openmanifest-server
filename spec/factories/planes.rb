# frozen_string_literal: true

# == Schema Information
#
# Table name: planes
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  min_slots              :integer
#  max_slots              :integer
#  hours                  :integer
#  next_maintenance_hours :integer
#  registration           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  dropzone_id            :bigint           not null
#  is_deleted             :boolean          default(FALSE)
#
FactoryBot.define do
  factory :plane do
    dropzone { nil }
    name { Faker::Color.color_name }
    registration { Faker::String.random(length: 3..12) }
    is_deleted { false }
    max_slots { Faker::Number.between(from: 4, to: 20) }

    factory :plane_with_loads do
      transient do
        load_count { 3 }
      end

      after(:create) do |plane, evaluator|
        create_list(:load, evaluator.load_count, plane: plane)

        plane.reload
      end
    end
  end
end
