# frozen_string_literal: true

module Mutations::Setup::Equipment
  class UpdateRig < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :rig, Types::RigType, null: true

    argument :attributes, Types::Input::RigInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = Rig.find(id)

      attrs = attributes.to_h.except(:packing_card)
      if attrs[:repack_expires_at]
        attrs[:repack_expires_at] = Time.at(attrs[:repack_expires_at])
      end

      if attributes[:packing_card]
        model.packing_card.attach(data: image)
        model.packing_card.variant(resize_to_limit: [1920, 1920])
      end
      model.assign_attributes(attrs.to_h)
      model.save!

      {
        rig: model.reload,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        rig: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      rig = Rig.find(id)

      if rig.user_id && rig.user_id != context[:current_resource].id
        [
          false, {
            errors: [
              "You can't update other users' rigs",
            ],
          },
        ]
      elsif rig.dropzone_id && !context[:current_resource].can?(:updateDropzoneRig, dropzone_id: rig.dropzone_id)
        [
          false, {
            errors: [
              "You can't update rigs for this dropzone",
            ],
          },
        ]
      else
        true
      end
    end
  end
end
