# frozen_string_literal: true

module Types
  class DropzoneUserType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false

    field :dropzone, Types::DropzoneType, null: false
    field :user, Types::UserType, null: false
    field :slots, Types::SlotType.connection_type, null: true
    def slots
      object.slots.includes(:load, :jump_type, :ticket_type).order(created_at: :desc)
    end

    field :unseen_notifications, Int, null: false
    def unseen_notifications
      object.notifications.where(is_seen: false).count
    end

    field :notifications, Types::NotificationType.connection_type, null: true
    def notifications
      # Only allow viewing this if this is the current user
      if context[:current_resource].id == object.user.id
        object.notifications.order(created_at: :desc)
      else
        []
      end
    end


    field :transactions, Types::TransactionType.connection_type, null: true
    def transactions
      is_self = context[:current_resource].id == object.user.id
      can_see_others = context[:current_resource].can?("readUserTransactions", dropzone_id: object.dropzone_id)


      if can_see_others || is_self
        object.transactions.order(created_at: :desc)
      else
        []
      end
    end

    field :rig_inspections, [Types::RigInspectionType], null: true
    field :expires_at, Int, null: true
    field :credits, Int, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

    field :available_rigs, [Types::RigType], null: true,
    description: "Get user rigs that have been inspected and marked as OK + dropzone rigs" do
      argument :is_tandem, Boolean, required: false
    end
    def available_rigs(is_tandem: nil)
      user_rigs = object.rig_inspections.filter_map { |inspection| inspection.rig if inspection.is_ok? }.select do |rig|
        rig.repack_expires_at > DateTime.now
      end

      if is_tandem
        return object.dropzone.rigs.where(rig_type: "tandem")
      else
        dropzone_rigs = object.dropzone.rigs.where(is_public: true)
      end

      user_rigs.to_a + dropzone_rigs.to_a
    end

    field :has_rig_inspection, Boolean, null: false
    def has_rig_inspection
      object.rig_inspections && object.rig_inspections.any?(&:is_ok?)
    end

    field :has_membership, Boolean, null: false
    def has_membership
      !!object.expires_at && object.expires_at > DateTime.now
    end

    field :has_credits, Boolean, null: false
    def has_credits
      !!object.credits
    end

    field :has_exit_weight, Boolean, null: false
    def has_exit_weight
      !!object.user.exit_weight
    end

    field :has_reserve_in_date, Boolean, null: false
    def has_reserve_in_date
      object.rig_inspections && object.rig_inspections.any? do |inspection|
        inspection.rig && inspection.rig.repack_expires_at && inspection.rig.repack_expires_at > DateTime.now
      end
    end



    field :has_license, Boolean, null: false
    def has_license
      object.user.license.present?
    end


    field :role, Types::UserRoleType, null: true
    def role
      object.user_role
    end

    field :permissions, [Types::PermissionType], null: true
    def permissions
      object.all_permissions.pluck(:name)
    end
  end
end
