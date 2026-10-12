# frozen_string_literal: true

module Types::Equipment
  class Rig < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :make, String, null: true
    field :model, String, null: true
    field :serial, String, null: true
    field :canopy_size, Int, null: true
    field :pack_value, Int, null: true
    field :rig_type, String, null: true
    field :repack_expires_at, Int, null: true
    field :maintained_at, Int, null: true
    field :is_public, Boolean, null: false
    timestamp_fields
    async_field :operator, Types::OperatorType, null: true
    async_field :owner, Types::Users::User, null: true, method: :user
    field :packing_card, String, null: true
    def packing_card
      return nil unless object.packing_card.attached?
      Rails.application.routes.url_helpers.url_for(object.packing_card)
    end

    field :rig_inspections, Types::Equipment::RigInspection, null: true do
      argument :operator_id, GraphQL::Types::ID, required: true
    end
    def rig_inspections(operator_id: nil)
      operator = Operator.find_by(id: operator_id)
      return nil unless operator
      rig.rig_inspections.at_operator(operator)
    end
  end
end
