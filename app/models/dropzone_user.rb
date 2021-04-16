# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  dropzone_id :integer          not null
#  role        :integer
#  credits     :float
#  expires_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class DropzoneUser < ApplicationRecord
  belongs_to :user
  belongs_to :dropzone
  belongs_to :user_role

  def permissions
    Permission.includes(user_role: :dropzone_users).where(
      dropzone: dropzone_id,
      user_roles: {
        user_id: user.id
      }
    ).pluck(:name)
  end
end
