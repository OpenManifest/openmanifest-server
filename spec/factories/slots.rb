# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :bigint           not null, primary key
#  ticket_type_id    :bigint
#  load_id           :bigint
#  equipment_id            :bigint
#  activity_type_id      :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  body_mass_kg       :float
#  guest_id      :bigint
#  is_paid           :boolean
#  transaction_id    :bigint
#  guest_slot_id :bigint
#  group_number      :integer          default(0), not null
#  membership_id  :bigint
#
FactoryBot.define do
  factory :slot do
    add_attribute(:load)
    transient do
      operator { nil }
    end
    membership do
      available_existing = operator.memberships.where.not(
        id: load.slots.pick(:membership_id)
      )
      available_existing || create(:membership, operator: operator)
    end
    group_number { 0 }
    ticket_type { create(:ticket_type, operator: load.vehicle.operator) }
    is_paid { false }
    body_mass_kg { membership.user.body_mass_kg }
    activity_type { membership.user.certification_level.permitted_activities.sample.activity_type }
    created_by { membership }
  end
end
