# frozen_string_literal: true

module Mutations::Manifest
  class UpdateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:, id:)
      model = Load.find(id)

      attrs = attributes.to_h
      if attrs[:dispatch_at]
        attrs[:dispatch_at] = Time.at(attrs[:dispatch_at])
      end

      if attributes[:plane_id]
        plane = Plane.find(attributes[:plane_id])

        # If the plane is too small to fit all manifested slot,
        # show an error
        if plane[:max_slots] < model.slots.count
          return {
            load: nil,
            errors: ["This plane cannot fit all manifested jumpers"],
            field_errors: nil,
          }
        end

        # If the plane changes, change max slots on the load accordingly
        if plane[:max_slots] != model.max_slots
          model.max_slots = plane[:max_slots]
        end
      end

      model.update!(attrs)

      {
        load: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        load: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateLoad",
        dropzone_id: Load.find(id).plane.dropzone_id
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create ticket addons"
            ]
          }
      end
    end
  end
end
