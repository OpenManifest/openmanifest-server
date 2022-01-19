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
      :undeleteDropzone,

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
      :undeleteUserSlot,

      :createStudentSlot,
      :updateStudentSlot,
      :deleteStudentSlot,
      :undeleteStudentSlot,

      :createTicketType,
      :updateTicketType,
      :deleteTicketType,
      :undeleteTicketType,

      :createExtra,
      :updateExtra,
      :deleteExtra,
      :readExtra,
      :undeleteExtra,

      :createPlane,
      :updatePlane,
      :deletePlane,
      :undeletePlane,

      :createRig,
      :updateRig,
      :deleteRig,
      :readRig,
      :undeleteRig,

      :createDropzoneRig,
      :updateDropzoneRig,
      :deleteDropzoneRig,
      :readDropzoneRig,
      :undeleteDropzoneRig,

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
      :undeleteUser,

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
