# frozen_string_literal: true

module Mutations::Setup::Equipment
  class CreateEquipment < Mutations::BaseMutation
    include OfficeAccess

    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :equipment, Types::Equipment::Equipment, null: true

    argument :attributes, Types::Input::EquipmentInput, required: true

    def resolve(attributes:)
      owner = attributes[:user_id] ? User.find(attributes[:user_id]) : Operator.find(attributes[:operator_id])
      model = owner.equipment.new
      kind = kind_for(owner: owner, kind_id: attributes[:kind_id])
      return { equipment: nil, field_errors: [{ field: "kind", message: "can't be blank" }], errors: ["Choose what kind of equipment it is"] } unless kind

      # Checked before anything is saved: a bad picture creates no equipment
      packing_card = Support::ImageUpload.attachable(attributes[:packing_card], name: "packing-card") if attributes[:packing_card]
      assign_equipment(model, attributes, kind: kind)

      model.save!
      model.packing_card.attach(**packing_card) if packing_card

      {
        equipment: model,
        errors: nil,
        field_errors: nil,
      }
    rescue Support::ImageUpload::Invalid => e
      { equipment: nil, field_errors: [{ field: "packing_card", message: e.message }], errors: [e.message] }
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

    def authorized?(attributes: nil)
      if attributes[:user_id] && attributes[:user_id] != context[:current_resource].id && !staff_of_member?(User.find_by(id: attributes[:user_id]))
        [
          false, {
            errors: [
              "You can't create equipment for other users",
            ],
          },
        ]
      elsif attributes[:operator_id] && !context[:current_resource].can?("createEquipment", operator_id: attributes[:operator_id])
        [
          false, {
            errors: [
              "You can't create equipment for this operator",
            ],
          },
        ]
      elsif attributes[:kind_id] && !kind_of_owner?(attributes)
        [false, { errors: ["That kind of equipment is not kept by the owner's operator"] }]
      else
        true
      end
    end

    private

    # An operator's equipment has a kind of the operator; a member's own has a kind of an operator they are a member of
    def kind_of_owner?(attributes)
      kind = EquipmentKind.kept.find_by(id: attributes[:kind_id])
      return false unless kind

      if attributes[:operator_id]
        kind.operator_id == attributes[:operator_id]
      else
        Membership.kept.exists?(user_id: attributes[:user_id], operator_id: kind.operator_id)
      end
    end
  end
end
