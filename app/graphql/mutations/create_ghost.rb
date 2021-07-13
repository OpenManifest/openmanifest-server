module Mutations
  class CreateGhost < Mutations::BaseMutation
    field :user, Types::UserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::GhostInput, required: true

    def resolve(attributes:)
      # Throw if the user exists
      if User.exists?(email: attributes[:email]) || User.exists?(unconfirmed_email: attributes[:email])
        return {
          user: nil,
          errors: ["User already exists"],
          field_errors: nil
        }
      end
      model = User.find_or_initialize_by(
        unconfirmed_email: attributes[:email],
      )

      attrs = attributes.to_h.except(:role_id, :dropzone_id)
      model.assign_attributes(attrs.merge(
        password: SecureRandom.urlsafe_base64(9)
      ))

      model.save!

      if attributes[:dropzone_id].present?
        DropzoneUser.create(
          dropzone_id: attributes[:dropzone_id],
          user_role_id: attributes[:role_id],
          user_id: model.id
        )
      end

      {
        user: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        user: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        user: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        user: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      unless context[:current_resource].can?(:createUser, dropzone_id: attributes[:dropzone_id])
        return false, {
          errors: [
            "You're not allowed to create users at this dropzone"
          ]
        }
      end
      true
    end
  end
end