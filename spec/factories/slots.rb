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
#  dropzone_user_id  :bigint
#
FactoryBot.define do
  factory :slot do
    add_attribute(:load)
    transient do
      dropzone { nil }
    end
    dropzone_user do
      available_existing = dropzone.dropzone_users.where.not(
        id: load.slots.pick(:dropzone_user_id)
      )
      available_existing || create(:dropzone_user, dropzone: dropzone)
    end
    group_number { 0 }
    ticket_type { create(:ticket_type, dropzone: load.plane.dropzone) }
    is_paid { false }
    exit_weight { dropzone_user.user.exit_weight }
    jump_type { dropzone_user.user.license.licensed_jump_types.sample.jump_type }
    rig { dropzone_user.user.rigs.sample }
  end
end
