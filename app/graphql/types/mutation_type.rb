# frozen_string_literal: true

module Types
  class MutationType < Types::Base::Object
    field_class GraphqlDevise::Types::BaseField
    # Access
    field :revoke_permission,           mutation: Mutations::Access::RevokePermission
    field :grant_permission,            mutation: Mutations::Access::GrantPermission
    field :update_notification,         mutation: Mutations::Users::UpdateNotification
    field :update_role,                 mutation: Mutations::Access::UpdateRole
    field :update_visibility,           mutation: Mutations::Access::UpdateVisibility
    field :update_daily_log, mutation: Mutations::Operator::UpdateDailyLog

    # Users
    field :login_with_facebook,         mutation: Mutations::Users::Login::Facebook, authenticate: false,
                                        deprecation_reason: "Facebook login removed (D4)"
    field :login_with_apple,            mutation: Mutations::Users::Login::Apple, authenticate: false
    field :create_ghost,                mutation: Mutations::Users::CreateGhost
    field :join_operator,               mutation: Mutations::Users::JoinOperator
    field :update_membership, mutation: Mutations::Users::UpdateMembership
    field :update_user,                 mutation: Mutations::Users::UpdateUser
    field :delete_user,                 mutation: Mutations::Users::DeleteUser
    field :join_certification_body,             mutation: Mutations::Users::JoinCertificationBody
    field :add_user_qualification,              mutation: Mutations::Users::AddUserQualification

    # Setup
    field :delete_vehicle, mutation: Mutations::Setup::Vehicles::DeleteVehicle
    field :create_vehicle, mutation: Mutations::Setup::Vehicles::CreateVehicle
    field :update_vehicle, mutation: Mutations::Setup::Vehicles::UpdateVehicle
    field :delete_operator,             mutation: Mutations::Setup::Operators::DeleteOperator
    field :create_operator,             mutation: Mutations::Setup::Operators::CreateOperator
    field :update_operator,             mutation: Mutations::Setup::Operators::UpdateOperator
    field :reload_weather_condition,    mutation: Mutations::Setup::Operators::ReloadWeatherCondition
    field :create_weather_condition,    mutation: Mutations::Setup::Operators::CreateWeatherCondition
    field :update_equipment, mutation: Mutations::Setup::Equipment::UpdateEquipment
    field :archive_equipment, mutation: Mutations::Setup::Equipment::DeleteEquipment
    field :create_equipment, mutation: Mutations::Setup::Equipment::CreateEquipment
    field :update_form_template, mutation: Mutations::Setup::EquipmentInspections::UpdateFormTemplate
    field :update_equipment_inspection, mutation: Mutations::Setup::EquipmentInspections::UpdateEquipmentInspection
    field :create_equipment_inspection, mutation: Mutations::Setup::EquipmentInspections::CreateEquipmentInspection
    field :update_extra,                mutation: Mutations::Setup::Tickets::UpdateExtra
    field :create_extra,                mutation: Mutations::Setup::Tickets::CreateExtra
    field :create_ticket_type,          mutation: Mutations::Setup::Tickets::CreateTicketType
    field :update_ticket_type,          mutation: Mutations::Setup::Tickets::UpdateTicketType
    field :archive_ticket_type,         mutation: Mutations::Setup::Tickets::DeleteTicketType
    field :create_crew_role,            mutation: Mutations::Setup::CrewRoles::CreateCrewRole
    field :update_crew_role,            mutation: Mutations::Setup::CrewRoles::UpdateCrewRole
    field :archive_crew_role,           mutation: Mutations::Setup::CrewRoles::ArchiveCrewRole
    field :create_destination,          mutation: Mutations::Setup::Destinations::CreateDestination
    field :update_destination,          mutation: Mutations::Setup::Destinations::UpdateDestination
    field :archive_destination,         mutation: Mutations::Setup::Destinations::ArchiveDestination

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
