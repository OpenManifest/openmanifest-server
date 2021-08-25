# frozen_string_literal: true

# == Schema Information
#
# Table name: slot_extras
#
#  id         :bigint           not null, primary key
#  slot_id    :bigint           not null
#  extra_id   :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SlotExtra < ApplicationRecord
  belongs_to :slot
  belongs_to :extra
end
