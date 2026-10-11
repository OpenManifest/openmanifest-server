# frozen_string_literal: true

module Mutations::Setup::Equipment
  class DeleteRig < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :rig, Types::Equipment::Rig, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Rig.find(id)

      # Archive rather than destroy: slots and inspections keep pointing at the rig
      model.discard

      {
        rig: model.reload,
        field_errors: nil,
        errors: nil,
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
      rig = Rig.find_by(id: id)
      return [false, { errors: ["Rig not found"] }] unless rig

      # A dropzone rig is deleted by staff of its dropzone
      if rig.dropzone_id
        return true if context[:current_resource].can?(:deleteDropzoneRig, dropzone_id: rig.dropzone_id)
      else
        return true if rig.user_id == context[:current_resource].id

        # Staff of the one dropzone the owner belongs to may archive it too (jumpers hold deleteRig as well, but
        # only for their own rigs, which the ownership check above covers)
        dropzone_ids = rig.user.dropzone_users.pluck(:dropzone_id)
        return true if dropzone_ids.count == 1 && context[:current_resource].can?(
          :deleteDropzoneRig,
          dropzone_id: dropzone_ids.first
        )
      end

      [
        false, {
          errors: ["You cant delete this rig"],
        },
      ]
    end
  end
end
