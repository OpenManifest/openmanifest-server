module Mutations
  class UpdateDropzoneUser < Mutations::BaseMutation
    field :dropzone_user, Types::DropzoneUserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::DropzoneUserInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = DropzoneUser.find(id)

      attrs = attributes.to_h
      if attrs[:expires_at]
        attrs[:expires_at] = Time.at(attributes[:expires_at])
      end
      model.assign_attributes(attrs)
      model.save!

      {
        dropzone_user: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      dropzone_user = DropzoneUser.find(id)

      allowed_to_update_others = context[:current_resource].can?("updateUser", dropzone_id: dropzone_user.dropzone_id)

      if !allowed_to_update_others
        return false, {
          errors: [
            "You don't have permission to update this"
          ]
        }
      else
        true
      end
    end
  end
end