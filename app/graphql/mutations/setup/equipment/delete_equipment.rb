# frozen_string_literal: true

module Mutations::Setup::Equipment
  class DeleteEquipment < Mutations::BaseMutation
    include OfficeAccess

    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :equipment, Types::Equipment::Equipment, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Equipment.find(id)

      # Archive rather than destroy: slots and inspections keep pointing at the equipment
      model.discard

      {
        equipment: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        equipment: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        equipment: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        equipment: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      equipment = Equipment.find_by(id: id)
      return [false, { errors: ["Equipment not found"] }] unless equipment

      # An operator equipment is deleted by staff of its operator
      if equipment.operator_id
        return true if context[:current_resource].can?(:deleteOperatorEquipment, operator_id: equipment.operator_id)
      else
        return true if equipment.user_id == context[:current_resource].id
        return true if staff_of_member?(equipment.user)

        # Staff of the one operator the owner belongs to may archive it too (jumpers hold deleteEquipment as well, but
        # only for their own equipment, which the ownership check above covers)
        operator_ids = equipment.user.memberships.pluck(:operator_id)
        return true if operator_ids.one? && context[:current_resource].can?(
          :deleteOperatorEquipment,
          operator_id: operator_ids.first
        )
      end

      [
        false, {
          errors: ["You cant delete this equipment"],
        },
      ]
    end
  end
end
