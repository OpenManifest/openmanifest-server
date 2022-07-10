# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class UpdateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:, id:)
      model = Dropzone.find(id)
      attrs = attributes.to_h.except(:banner)
      attrs[:image] = attributes[:banner] if attributes[:banner].present?
      if attrs[:request_publication] && !model.is_public
        # Send a notification to administrators
        User.where(moderation_role: "administrator").each do |user|
          Notification.create(
            received_by: user,
            message: "Dropzone #{model.name} has requested publication",
            notification_type: :publication_requested,
            resource: model,
            sent_by: model.dropzone_users.find_by(user_id: context[:current_resource].id)
          )
        end
      end
      model.update!(attrs)

      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      dropzone = Dropzone.find(id)

      if attributes[:is_public] && dropzone.is_public != attributes[:is_public]
        if User.moderation_roles[context[:current_resource].moderation_role] < User.moderation_roles["moderator"]
          return false, {
            errors: [
              "You cant modify the publication state of this dropzone"
            ]
          }
        end
      end

      if context[:current_resource].can?(
        "updateDropzone",
        dropzone_id: id
      )
        return true
      end
      return false, {
        errors: [
          "You don't have permissions to edit this dropzone"
          ]
        }
    end
  end
end
