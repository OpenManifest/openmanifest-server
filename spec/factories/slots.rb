# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :bigint           not null, primary key
#  ticket_type_id    :bigint
#  load_id           :bigint
#  rig_id            :bigint
#  jump_type_id      :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exit_weight       :float
#  passenger_id      :bigint
#  is_paid           :boolean
#  transaction_id    :bigint
#  passenger_slot_id :bigint
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
    ticket_type { create(:ticket_type, operator: load.plane.operator) }
    is_paid { false }
    exit_weight { membership.user.exit_weight }
    jump_type { membership.user.license.licensed_jump_types.sample.jump_type }
    rig { membership.user.rigs.sample }
    created_by { membership }
  end
end
