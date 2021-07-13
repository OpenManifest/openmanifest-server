# == Schema Information
#
# Table name: user_permissions
#
#  id               :integer          not null, primary key
#  permission_id    :integer          not null
#  dropzone_user_id :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class UserPermission < ApplicationRecord
  belongs_to :permission
  belongs_to :dropzone_user
end
