[
  :tandem_passenger,
  :student,
  :fun_jumper,
  :coach,
  :aff_instructor,
  :tandem_instructor,
  :chief_instructor,
  :manifest,
  :owner
].map do |role|
  Role.create(name: role)
end

[
  :updateDropzone,
  :deleteDropzone,

  :createLoad,
  :updateLoad,
  :deleteLoad,
  :readLoad,

  :createSlot,
  :updateSlot,
  :deleteSlot,
  
  :createUsersSlot,
  :updateUsersSlot,
  :deleteUsersSlot,

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