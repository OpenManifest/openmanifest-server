# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :createWeatherCondition, mutation: Mutations::CreateWeatherCondition
    field :reloadWeatherCondition, mutation: Mutations::ReloadWeatherCondition
    field :createGhost, mutation: Mutations::CreateGhost
    field :loginWithFacebook, mutation: Mutations::SignUpWithFacebook
    field :createOrder, mutation: Mutations::CreateOrder
    field :revokePermission, mutation: Mutations::RevokePermission
    field :grantPermission, mutation: Mutations::GrantPermission
    field :updateNotification, mutation: Mutations::UpdateNotification
    field :updateFormTemplate, mutation: Mutations::UpdateFormTemplate
    field :updateRigInspection, mutation: Mutations::UpdateRigInspection
    field :createRigInspection, mutation: Mutations::CreateRigInspection
    field :updateDropzoneUser, mutation: Mutations::UpdateDropzoneUser
    field :updateRig, mutation: Mutations::UpdateRig
    field :archiveRig, mutation: Mutations::DeleteRig
    field :createRig, mutation: Mutations::CreateRig
    field :updateExtra, mutation: Mutations::UpdateExtra
    field :createExtra, mutation: Mutations::CreateExtra
    field :updateUser, mutation: Mutations::UpdateUser
    field :deleteUser, mutation: Mutations::DeleteUser
    field :joinFederation, mutation: Mutations::JoinFederation
    field :createTicketType, mutation: Mutations::CreateTicketType
    field :updateTicketType, mutation: Mutations::UpdateTicketType
    field :archiveTicketType, mutation: Mutations::DeleteTicketType
    field :deleteLoad, mutation: Mutations::DeleteLoad
    field :createLoad, mutation: Mutations::CreateLoad
    field :updateLoad, mutation: Mutations::UpdateLoad
    field :finalizeLoad, mutation: Mutations::FinalizeLoad
    field :deleteSlot, mutation: Mutations::DeleteSlot
    field :createSlot, mutation: Mutations::CreateSlot
    field :createSlots, mutation: Mutations::CreateSlots
    field :updateSlot, mutation: Mutations::UpdateSlot
    field :deletePlane, mutation: Mutations::DeletePlane
    field :createPlane, mutation: Mutations::CreatePlane
    field :updatePlane, mutation: Mutations::UpdatePlane
    field :deleteDropzone, mutation: Mutations::DeleteDropzone
    field :createDropzone, mutation: Mutations::CreateDropzone
    field :updateDropzone, mutation: Mutations::UpdateDropzone
    field :updateRole, mutation: Mutations::UpdateRole
  end
end
