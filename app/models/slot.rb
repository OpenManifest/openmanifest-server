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
#  exit_weight    :float
#
class Slot < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :passenger, optional: true
  belongs_to :ticket_type
  belongs_to :load
  belongs_to :rig, optional: true
  belongs_to :jump_type

  has_many :slot_extras
  has_many :extras, through: :slot_extras
  has_many :transactions

  def charge_credits!
    # Tandem passengers are not real accounts and will
    # not be charged credits:
    return unless user.present?

    # Find Dropzone user:
    if dz_user = DropzoneUser.find_by(
        dropzone_id: load.plane.dropzone_id,
        user_id: user.id
      )
      transactions.create!(
        status: :paid,
        # Make negative to charge credits
        amount: cost * -1,
        dropzone_user: dz_user
      )
      update(is_paid: true)
    end
  end
  

  def cost
    extras.map(&:cost).reduce(&:+) + ticket_type.cost
  end

  def ready?
    (passenger.present? || user.present?) && ticket_type.present? && load.present? && jump_type.present?
  end

  def wing_loading
    if rig && rig.canopy_size && exit_weight
      weight_in_lbs = exit_weight * 2.20462
      weight_in_lbs /= canopy_size
    end
  end
end
