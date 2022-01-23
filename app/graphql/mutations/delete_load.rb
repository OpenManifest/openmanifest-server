# frozen_string_literal: true

module Mutations
  class DeleteLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Load.find(id)

      model.discard
      {
        load: model.reload,
        field_errors: nil,
        errors: nil
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this aircraft"]
      }

    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        load: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      model = Load.find(id)


      if context[:current_resource].can?(
        :deleteLoad,
        dropzone_id: model.dropzone_id
      )
        true
      else
        return false, {
          errors: ["You cant delete this load"]
        }
      end
    end
  end
end
