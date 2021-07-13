# == Schema Information
#
# Table name: user_role_permissions
#
#  id            :integer          not null, primary key
#  permission_id :integer          not null
#  user_role_id  :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class UserRolePermission < ApplicationRecord
  belongs_to :permission
  belongs_to :user_role
end
