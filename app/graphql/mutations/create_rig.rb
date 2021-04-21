module Mutations
  class CreateRig < Mutations::BaseMutation
    field :rig, Types::RigType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::RigInput, required: true

    def resolve(attributes:)
      model = if attributes[:user_id]
                User.find(attributes[:user_id]).rigs.new 
              else
                Dropzone.find(attributes[:dropzone_id]).rigs.new
              end
      model.assign_attributes(attributes.to_h)

      model.save!

      {
        rig: model,
        errors: nil,
        field_errors: nil,
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

    def authorized?(attributes: nil)
      if attributes[:user_id] && attributes[:user_id] != context[:current_resource].id
        return false, {
          errors: [
            "You can't create rigs for other users"
          ]
        }
      elsif attributes[:dropzone_id] && !context[:current_resource].can?("updateDropzone", dropzone_id: attributes[:dropzone_id])
        return false, {
          errors: [
            "You can't create rigs for this dropzone"
          ]
        }
      else
        true
      end
    end
  end
end