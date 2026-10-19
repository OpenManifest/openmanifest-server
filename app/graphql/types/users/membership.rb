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
    field :equipment_inspections, [Types::Equipment::EquipmentInspection], null: true
    def equipment_inspections
      preload(:equipment_inspections).equipment_inspections
    end

    field :credits_cents, Int, null: true, description: "The member's credits in cents"
    field :purchases, Types::Payments::Order.connection_type, null: true
    field :sales, Types::Payments::Order.connection_type, null: true

    # TODO: Remove and move to top level query
    field :available_equipment, [Types::Equipment::Equipment], null: true,
                                                               description: "Get user equipment that have been inspected and marked as OK + operator equipment" do
      argument :is_tandem, Boolean, required: false, description: "Skydiving: the tandem rigs of the operator"
      argument :kind, String, required: false, description: "Only items of the equipment kind with this key"
      argument :load_id, Integer, required: false,
                                  description: "Filter out equipment already occupied for a load"
    end

    field :eligibility, Types::Manifest::MembershipEligibility, null: false,
                                                                description: "Whether the member is ready to manifest, rule by rule (membership, credits, certification, body mass, equipment, …)" do
      argument :load_id, GraphQL::Types::ID, required: false, description: "Also whether the load has a seat for them"
    end

    field :has_equipment_inspection, Boolean, null: false
    field :has_membership, Boolean, null: false
    field :has_credits, Boolean, null: false
    field :has_body_mass_kg, Boolean, null: false
    field :has_equipment_in_service, Boolean, null: false
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

    def available_equipment(load_id: nil, is_tandem: nil, kind: nil)
      return Skydiving::Rigs.tandem(object.operator) if is_tandem

      object.available_equipment(load_id: load_id, kind: kind)
    end

    def eligibility(load_id: nil)
      preload(:user, :operator, equipment_inspections: { equipment: :kind })
      load = dataloader.with(::Sources::Model, ::Load).load(load_id.to_i) if load_id
      ::Eligibility.summary(object, load: load)
    end

    def has_equipment_inspection
      preload(equipment_inspections: { equipment: :kind }).equipment_inspections.any? { |inspection| inspection.is_ok && inspection.current? }
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

    def has_equipment_in_service
      preload(equipment_inspections: { equipment: :kind }).equipment_inspections.any? do |inspection|
        inspection.equipment&.in_service?
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
