# frozen_string_literal: true

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

    :createChecklist,
    :updateChecklist,
    :deleteChecklist,
    :readChecklist,

    :readUser,
    :updateUser,
    :deleteUser,
    :createUser,

    :actAsPilot,
    :actAsLoadMaster,
    :actAsGCA,
    :actAsDZSO,
  ]
end
