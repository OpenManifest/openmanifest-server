module Mutations
  class CreateTransaction < Mutations::BaseMutation
    field :transaction, Types::TransactionType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::TransactionInput, required: true

    def resolve(attributes:)
      model = Transaction.create(attributes.to_h)

      model.save!

      {
        transaction: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        transaction: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        transaction: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        transaction: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      dz_user = DropzoneUser.find(attributes[:dropzone_user_id])

      if context[:current_resource].can?("createUserTransaction", dropzone_id: dz_user.dropzone.id)
        return false, {
          errors: [
            "You can't create transactions"
          ]
        }
      else
        true
      end
    end
  end
end