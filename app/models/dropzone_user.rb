# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  dropzone_id  :integer          not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :integer          not null
#
class DropzoneUser < ApplicationRecord
  belongs_to :user
  belongs_to :dropzone
  belongs_to :user_role
  has_many :transactions
  has_many :rig_inspections
  
  has_many :notifications, foreign_key: :received_by_id

  search_scope :search do
    attributes name: "user.name"
  end

  def permissions
    Permission.includes(user_role: :dropzone_users).where(
      dropzone: dropzone_id,
      user_roles: {
        user_id: user.id
      }
    ).pluck(:name)
  end
end
