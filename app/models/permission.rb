# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id           :integer          not null, primary key
#  name         :integer
#  user_role_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Permission < ApplicationRecord
  belongs_to :user_role
  enum name: [
    :updateDropzone,
    :deleteDropzone,

    :createLoad,
    :updateLoad,
    :deleteLoad,
    :readLoad,

    :createSlot,
    :updateSlot,
    :deleteSlot,


    :createUserSlot,
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
  ]
end
