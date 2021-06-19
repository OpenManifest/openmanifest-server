class UserRolePermission < ApplicationRecord
  belongs_to :permission
  belongs_to :user_role
end
