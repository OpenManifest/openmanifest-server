# frozen_string_literal: true

module Mutations::Users
  class UpdateNotification < Mutations::BaseMutation
    field :notification, Types::NotificationType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::NotificationInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = Notification.find(id)
      model.attributes = attributes.to_h

      model.save!
      {
        notification: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        notification: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        notification: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        notification: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end


    def authorized?(id: nil, attributes: nil)
      notification = Notification.find(id)

      if notification.received_by.user.id != context[:current_resource].id
        return false, {
          errors: [
            "Cannot modify other users' notifications"
          ]
        }
      else
        true
      end
    end
  end
end
