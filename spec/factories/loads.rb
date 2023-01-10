# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :bigint           not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#  gca_id         :bigint
#  load_master_id :bigint
#  pilot_id       :bigint
#  state          :integer
#  load_number    :integer
#
FactoryBot.define do
  factory :load do
    transient do
      slot_count { 0 }
    end
    plane
    is_open { true }
    state { "open" }
    max_slots { plane.max_slots }
    dispatch_at { nil }
    gca { nil }
    pilot { nil }

    before(:create) do |instance, evaluator|
      instance.assign_attributes(
        gca: instance.gca || instance.dropzone.dropzone_users.first || create(:dropzone_user, dropzone: instance.dropzone),
        pilot: instance.pilot || instance.dropzone.dropzone_users.first || create(:dropzone_user, dropzone: instance.dropzone),
      )
    end

    after(:create) do |instance, evaluator|
      create_list(:slot, evaluator.slot_count, load: instance, dropzone: instance.plane.dropzone)
      instance.reload
    end
  end
end
