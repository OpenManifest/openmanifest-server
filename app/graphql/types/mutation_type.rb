# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field_class GraphqlDevise::Types::BaseField
    # Access
    field :revoke_permission,           mutation: Mutations::Access::RevokePermission
    field :grant_permission,            mutation: Mutations::Access::GrantPermission
    field :update_notification,         mutation: Mutations::Users::UpdateNotification
    field :update_role,                 mutation: Mutations::Access::UpdateRole
    field :update_visibility,           mutation: Mutations::Access::UpdateVisibility

    # Users
    field :login_with_facebook,         mutation: Mutations::Users::Login::Facebook, authenticate: false
    field :login_with_apple,            mutation: Mutations::Users::Login::Apple, authenticate: false
    field :create_ghost,                mutation: Mutations::Users::CreateGhost
    field :update_dropzone_user,        mutation: Mutations::Users::UpdateDropzoneUser
    field :update_user,                 mutation: Mutations::Users::UpdateUser
    field :delete_user,                 mutation: Mutations::Users::DeleteUser
    field :join_federation,             mutation: Mutations::Users::JoinFederation

    # Setup
    field :delete_plane,                mutation: Mutations::Setup::Aircrafts::DeletePlane
    field :create_plane,                mutation: Mutations::Setup::Aircrafts::CreatePlane
    field :update_plane,                mutation: Mutations::Setup::Aircrafts::UpdatePlane
    field :delete_dropzone,             mutation: Mutations::Setup::Dropzones::DeleteDropzone
    field :create_dropzone,             mutation: Mutations::Setup::Dropzones::CreateDropzone
    field :update_dropzone,             mutation: Mutations::Setup::Dropzones::UpdateDropzone
    field :reload_weather_condition,    mutation: Mutations::Setup::Dropzones::ReloadWeatherCondition
    field :create_weather_condition,    mutation: Mutations::Setup::Dropzones::CreateWeatherCondition
    field :update_rig,                  mutation: Mutations::Setup::Equipment::UpdateRig
    field :archive_rig,                 mutation: Mutations::Setup::Equipment::DeleteRig
    field :create_rig,                  mutation: Mutations::Setup::Equipment::CreateRig
    field :update_form_template,        mutation: Mutations::Setup::RigInspections::UpdateFormTemplate
    field :update_rig_inspection,       mutation: Mutations::Setup::RigInspections::UpdateRigInspection
    field :create_rig_inspection,       mutation: Mutations::Setup::RigInspections::CreateRigInspection
    field :update_extra,                mutation: Mutations::Setup::Tickets::UpdateExtra
    field :create_extra,                mutation: Mutations::Setup::Tickets::CreateExtra
    field :create_ticket_type,          mutation: Mutations::Setup::Tickets::CreateTicketType
    field :update_ticket_type,          mutation: Mutations::Setup::Tickets::UpdateTicketType
    field :archive_ticket_type,         mutation: Mutations::Setup::Tickets::DeleteTicketType

    # Manifest
    field :delete_load,                 mutation: Mutations::Manifest::DeleteLoad
    field :create_load,                 mutation: Mutations::Manifest::CreateLoad
    field :update_load,                 mutation: Mutations::Manifest::UpdateLoad
    field :finalize_load,               mutation: Mutations::Manifest::FinalizeLoad
    field :delete_slot,                 mutation: Mutations::Manifest::DeleteSlot
    field :create_slot,                 mutation: Mutations::Manifest::CreateSlot
    field :move_slot,                   mutation: Mutations::Manifest::MoveSlot
    field :create_slots,                mutation: Mutations::Manifest::CreateSlots
    field :update_slot,                 mutation: Mutations::Manifest::UpdateSlot

    # Payments
    field :create_order,                mutation: Mutations::Payments::CreateOrder
  end
end
