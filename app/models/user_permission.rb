# frozen_string_literal: true

# == Schema Information
#
# Table name: user_permissions
#
#  id               :bigint           not null, primary key
#  permission_id    :bigint           not null
#  dropzone_user_id :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class UserPermission < ApplicationRecord
  belongs_to :permission
  belongs_to :dropzone_user
end
