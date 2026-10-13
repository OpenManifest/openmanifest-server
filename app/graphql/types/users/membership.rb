# frozen_string_literal: true

module Types::Users
  class Membership < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::Wallet
    timestamp_fields
    field :id, GraphQL::Types::ID, null: false
    field :slots, Types::Manifest::Slot.connection_type, null: true
    field :unseen_notifications, Int, null: false
    field :notifications, Types::System::Notification.connection_type, null: true
    field :expires_at, Int, null: true
    field :rig_inspections, [Types::Equipment::RigInspection], null: true
    def rig_inspections
      preload(:rig_inspections).rig_inspections
    end

    field :credits_cents, Int, null: true, description: "The member's credits in cents"
    field :purchases, Types::Payments::Order.connection_type, null: true
    field :sales, Types::Payments::Order.connection_type, null: true

    # TODO: Remove and move to top level query
    field :available_rigs, [Types::Equipment::Rig], null: true,
                                                    description: "Get user rigs that have been inspected and marked as OK + operator rigs" do
      argument :is_tandem, Boolean, required: false
      argument :load_id, Integer, required: false,
                                  description: "Filter out rigs already occupied for a load"
    end

    field :has_rig_inspection, Boolean, null: false
    field :has_membership, Boolean, null: false
    field :has_credits, Boolean, null: false
    field :has_body_mass_kg, Boolean, null: false
    field :has_reserve_in_date, Boolean, null: false
    field :has_certification_level, Boolean, null: false

    async_field :role, Types::Access::UserRole, null: true, method: :user_role

    field :permissions, [Types::Access::PermissionType], null: true

    async_field :operator, Types::OperatorType, null: false
    async_field :certification_level, Types::Meta::CertificationLevel, null: true
    async_field :user, Types::Users::User, null: false

    async_field :activity_types, [Types::Meta::ActivityType], null: true
    field :user_certification, Types::Users::UserCertification, null: true, description: "The member's certification that gives the level, at a body the operator accepts"
    def user_certification
      accepted = ::UserCertification.where(user_id: object.user_id, certification_body_id: object.operator.certification_body_ids)
      accepted.find_by(certification_level_id: object.certification_level_id) || accepted.order(:id).first
    end

    def slots
      object.slots.includes(:load, :activity_type, :ticket_type).order(created_at: :desc)
    end

    def unseen_notifications
      dataloader.with(::Sources::UnseenNotificationCount).load(object.id)
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
      return object.operator.tandem_rigs if is_tandem

      object.available_rigs(load_id: load_id)
    end

    def has_rig_inspection
      preload(:rig_inspections).rig_inspections.any?(&:is_ok)
    end

    def has_membership
      return false unless object.expires_at
      object.expires_at > DateTime.now
    end

    def has_credits
      return object.credits > 0 if object.credits.present?
      false
    end

    def has_body_mass_kg
      !!preload(:user).user.body_mass_kg
    end

    def has_reserve_in_date
      preload(rig_inspections: :rig).rig_inspections.any? do |inspection|
        inspection.rig && inspection.rig.repack_expires_at && inspection.rig.repack_expires_at > DateTime.now
      end
    end

    def has_certification_level
      object.certification_level_id.present?
    end

    def permissions
      preload(:permissions, :role_permissions, :operator).permission_names
    end

    private

    # Loads the associations of this member together with those of the other members of the response, and gives the
    # member back (BUG-049)
    def preload(*associations)
      dataloader.with(::Sources::AssociationLoader, associations).load(object)
    end
  end
end
