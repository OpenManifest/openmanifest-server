# frozen_string_literal: true

module Mutations::Setup::Equipment
  class DeleteRig < Mutations::BaseMutation
    field :rig, Types::RigType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Rig.find(id)

      # Flag as deleted if any slots use this rig
      # or if this rig has been inspected
      if model.slots.empty? && model.rig_inspections.empty?
        model.destroy
      else
        model.discard
      end

      {
        rig: model.reload,
        field_errors: nil,
        errors: nil
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        rig: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      rig = Rig.find(id)
      dropzone_ids = rig.user.dropzone_users.pluck(:dropzone_id)

      return true if rig.user_id == context[:current_user].id
      return true if dropzone_ids.count == 1 && context[:current_resource].can?(
        :deleteUserRig,
        dropzone_id: dropzone_ids.first
      )

      return false, {
        errors: ["You cant delete this rig"]
      }
    end
  end
end
