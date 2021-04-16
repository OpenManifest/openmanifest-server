# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  ticket_type_id :integer
#  load_id        :integer
#  rig_id         :integer
#  jump_type_id   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Slot < ApplicationRecord
  belongs_to :user
  belongs_to :ticket_type
  belongs_to :load
  belongs_to :rig
  belongs_to :jump_type

  has_many :slot_extras
  has_many :extras, through: :slot_extras

  def cost
    extras.map(&:cost).reduce(&:+) + ticket_type.cost
  end

  def ready?
    user.present? && ticket_type.present? && load.present? && jump_type.present?
  end
end
