# frozen_string_literal: true

module Types::Users
  class DropzoneUser < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::Wallet
    field :id, GraphQL::Types::ID, null: false

    field :slots, Types::Manifest::Slot.connection_type, null: true

    field :unseen_notifications, Int, null: false

    field :notifications, Types::System::Notification.connection_type, null: true

    field :expires_at, Int, null: true

    field :rig_inspections, [Types::Equipment::RigInspection], null: true

    field :credits, Int, null: true

    field :purchases, Types::Payments::Order.connection_type, null: true

    field :sales, Types::Payments::Order.connection_type, null: true

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # TODO: Remove and move to top level query
    field :available_rigs, [Types::Equipment::Rig], null: true,
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

    field :role, Types::Access::UserRole, null: true, method: :user_role

    field :permissions, [Types::Access::PermissionType], null: true

    field :dropzone, Types::DropzoneType, null: false
    field :jump_types, [Types::Meta::JumpType], null: true
    field :license, Types::Meta::License, null: true
    field :user, Types::Users::User, null: false
    field :user_federation, Types::Users::UserFederation, null: true
    def user_federation
      ::UserFederation.find_by(
        user_id: object.user,
        federation_id: object.dropzone.federation_id
      )
    end

    def slots
      # TODO: Lookahead
      object.slots.includes(:load, :jump_type, :ticket_type).order(created_at: :desc)
    end

    def unseen_notifications
      # TODO: Counter culture
      object.notifications.unseen.count
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
      # TODO: N+1
      object.rig_inspections.exists?(is_ok: true)
    end

    def has_membership
      return false unless object.expires_at
      object.expires_at > DateTime.now
    end

    def has_credits
      return object.credits > 0 if object.credits.present?
      false
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
      object.license_id.present?
    end

    def permissions
      object.all_permissions.pluck(:name)
    end
  end
end
