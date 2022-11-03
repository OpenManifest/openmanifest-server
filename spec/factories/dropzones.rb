# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzones
#
#  id                         :bigint           not null, primary key
#  name                       :string
#  federation_id              :bigint
#  lat                        :float
#  lng                        :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_public                  :boolean
#  primary_color              :string
#  secondary_color            :string
#  is_credit_system_enabled   :boolean          default(FALSE)
#  rig_inspection_template_id :bigint
#  image                      :string
#  time_zone                  :string           default("Australia/Brisbane")
#  users_count                :integer          default(0), not null
#  slots_count                :integer          default(0), not null
#  loads_count                :integer          default(0), not null
#  credits                    :integer
#
FactoryBot.define do
  factory :dropzone do
    name { "Skydive #{Faker::Address.city}" }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    state { "public" }
    primary_color { Faker::Color.hex_color }
    secondary_color { Faker::Color.hex_color }
    is_credit_system_enabled { true }
    time_zone { "Australia/Brisbane" }
    federation { Federation.first }

    factory :dropzone_with_loads do
      transient do
        plane_count { 1 }
      end

      after(:create) do |dropzone, evaluator|
        dropzone.create_default_roles
        create_list(:plane_with_loads, evaluator.plane_count, dropzone: dropzone)

        # You may need to reload the record here, depending on your application
        dropzone.reload
      end
    end
  end
end
