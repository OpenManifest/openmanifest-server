# frozen_string_literal: true

# == Schema Information
#
# Table name: user_role_permissions
#
#  id            :bigint           not null, primary key
#  permission_id :bigint           not null
#  user_role_id  :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class UserRolePermission < ApplicationRecord
  belongs_to :permission
  belongs_to :user_role
end
