# frozen_string_literal: true

module Types
  class DropzoneUserType < Types::BaseObject
    implements Types::AnyResourceType
    implements Types::WalletType
    field :id, GraphQL::Types::ID, null: false

    field :slots, Types::SlotType.connection_type, null: true

    field :unseen_notifications, Int, null: false

    field :notifications, Types::NotificationType.connection_type, null: true

    field :expires_at, Int, null: true

    field :rig_inspections, [Types::RigInspectionType], null: true

    field :credits, Int, null: true

    field :purchases, Types::OrderType.connection_type, null: true

    field :sales, Types::OrderType.connection_type, null: true

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :available_rigs, [Types::RigType], null: true,
                                             description: "Get user rigs that have been inspected and marked as OK + dropzone rigs" do
      argument :is_tandem, Boolean, required: false
      argument :load_id, Integer, required: false,
                                  description: "Filter out rigs already occupied for a load"
    end

    field :has_rig_inspection, Boolean, null: false

    field :has_membership, Boolean, null: false

    field :has_credits, Boolean, null: false

    field :has_exit_weight, Boolean, null: false

    field :has_reserve_in_date, Boolean, null: false

    field :has_license, Boolean, null: false

    field :role, Types::UserRoleType, null: true, method: :user_role

    field :permissions, [Types::PermissionType], null: true

    field :dropzone, Types::DropzoneType, null: false
    field :jump_types, [Types::JumpTypeType], null: true
    field :license, Types::LicenseType, null: true
    field :user, Types::UserType, null: false
    field :user_federation, Types::UserFederationType, null: true
    def user_federation
      ::UserFederation.find_by(user_id: object.user, federation_id: object.dropzone.federation_id)
    end

    def slots
      object.slots.includes(:load, :jump_type, :ticket_type).order(created_at: :desc)
    end

    def unseen_notifications
      object.notifications.where(is_seen: false).count
    end

    def notifications
      # Only allow viewing this if this is the current user
      if context[:current_resource].id == object.user.id
        object.notifications.order(created_at: :desc)
      else
        []
      end
    end

    def available_rigs(load_id: nil, is_tandem: nil)
      return object.dropzone.tandem_rigs if is_tandem

      object.available_rigs(load_id: load_id)
    end

    def has_rig_inspection
      object.rig_inspections && object.rig_inspections.any?(&:is_ok?)
    end

    def has_membership
      !!object.expires_at && object.expires_at > DateTime.now
    end

    def has_credits
      !!object.credits
    end

    def has_exit_weight
      !!object.user.exit_weight
    end

    def has_reserve_in_date
      object.rig_inspections && object.rig_inspections.any? do |inspection|
        inspection.rig && inspection.rig.repack_expires_at && inspection.rig.repack_expires_at > DateTime.now
      end
    end

    def has_license
      object.license.present?
    end

    def permissions
      object.all_permissions.pluck(:name)
    end
  end
end
