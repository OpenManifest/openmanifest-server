# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :integer          not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dropzone_id :integer          not null
#
class UserRole < ApplicationRecord
  belongs_to :dropzone
  has_many :dropzone_users
  has_many :user_role_permissions, dependent: :destroy
  has_many :permissions, through: :user_role_permissions

  def grant!(permission_name)
    unless permissions.includes(:permissions).exists?(permissions: { name: permission_name })
      user_role_permissions.create(
        permission: Permission.find_or_create_by(name: permission_name)
      )
    end
  end

  def revoke!(permission_name)
    user_role_permissions.includes(:permission).where(permission: { name: permission_name }).destroy_all
  end
end
