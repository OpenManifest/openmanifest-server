# frozen_string_literal: true

# == Schema Information
#
# Table name: operators
#
#  id                         :bigint           not null, primary key
#  name                       :string
#  lat                        :float
#  lng                        :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_public                  :boolean
#  primary_color              :string
#  secondary_color            :string
#  is_credit_system_enabled   :boolean          default(FALSE)
#  equipment_inspection_template_id :bigint
#  image                      :string
#  time_zone                  :string           default("Australia/Brisbane")
#  users_count                :integer          default(0), not null
#  slots_count                :integer          default(0), not null
#  loads_count                :integer          default(0), not null
#
FactoryBot.define do
  factory :operator do
    name { "Skydive #{Faker::Address.city}" }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    state { "public" }
    primary_color { Faker::Color.hex_color }
    secondary_color { Faker::Color.hex_color }
    is_credit_system_enabled { true }
    industry { "skydiving" }
    time_zone { "Australia/Brisbane" }
    certification_bodies { [CertificationBody.first] }

    after(:create) do |operator|
      Setup::Operators::Access::CreateDefaults.run!(operator: operator)
      CrewRole.create_presets!(operator)
      EquipmentKind.create_presets!(operator)
    end

    factory :operator_with_loads do
      transient do
        vehicle_count { 1 }
      end

      after(:create) do |operator, evaluator|
        create(:membership, operator: operator)
        create_list(:vehicle_with_loads, evaluator.vehicle_count, operator: operator.reload)

        # You may need to reload the record here, depending on your application
        operator.reload
      end
    end
  end
end
