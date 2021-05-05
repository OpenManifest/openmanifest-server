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
  has_many :permissions, dependent: :delete_all
  belongs_to :dropzone
  has_many :dropzone_users

  def grant!(permission_name)
    unless permissions.exists?(name: permission_name)
      permissions << Permission.find_or_create_by(name: permission_name)
      save
    end
  end

  def revoke!(permission_name)
    permissions.where(name: permission_name).delete_all
  end
end
