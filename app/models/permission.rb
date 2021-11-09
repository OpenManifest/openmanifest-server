# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#
class Permission < ApplicationRecord
  scope :without_acting, -> { where("name NOT LIKE (?)", "actAs%") }
  scope :only_acting, -> { where("name LIKE (?)", "actAs%") }

  validates_presence_of :name
  has_many :user_role_permissions, dependent: :destroy
  has_many :user_permissions, dependent: :destroy

  def self.names
    [
      :updateDropzone,
      :deleteDropzone,

      :updateWeatherConditions,

      :createLoad,
      :updateLoad,
      :deleteLoad,
      :readLoad,

      :createSlot,
      :createDoubleSlot,
      :updateSlot,
      :deleteSlot,


      :createUserSlot,
      :createUserDoubleSlot,
      :createUserSlotWithSelf,
      :updateUserSlot,
      :deleteUserSlot,

      :createStudentSlot,
      :updateStudentSlot,
      :deleteStudentSlot,

      :createTicketType,
      :updateTicketType,
      :deleteTicketType,

      :createExtra,
      :updateExtra,
      :deleteExtra,
      :readExtra,

      :createPlane,
      :updatePlane,
      :deletePlane,

      :createRig,
      :updateRig,
      :deleteRig,
      :readRig,

      :createDropzoneRig,
      :updateDropzoneRig,
      :deleteDropzoneRig,
      :readDropzoneRig,

      :readPermissions,
      :updatePermissions,

      :createPackjob,
      :updatePackjob,
      :deletePackjob,
      :readPackjob,

      :createFormTemplate,
      :updateFormTemplate,
      :deleteFormTemplate,
      :readFormTemplate,

      :readUser,
      :updateUser,
      :deleteUser,
      :createUser,

      :actAsPilot,
      :actAsLoadMaster,
      :actAsGCA,
      :actAsDZSO,
      :actAsRigInspector,

      :createUserTransaction,
      :readUserTransactions,

      :grantPermission,
      :revokePermission
    ]
  end
end
