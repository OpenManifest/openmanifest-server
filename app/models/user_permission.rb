class UserPermission < ApplicationRecord
  belongs_to :permission
  belongs_to :dropzone_user
end
