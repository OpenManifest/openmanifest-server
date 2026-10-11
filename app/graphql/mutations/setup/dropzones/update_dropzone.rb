# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class UpdateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::DropzoneInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      model = Dropzone.find(id)
      attrs = attributes.to_h.except(:banner)
      Support::ImageUpload.attach(model.banner, attributes[:banner], name: "banner") if attributes[:banner]
      # The state machine's event has the name of the request_publication column and takes over its accessors, so the
      # request is made through the event; a private dropzone moves to in_review and the moderators are told, once
      if attrs.delete(:request_publication) && model.state == "private"
        announce_publication_request(model)
        model.fire_state_event(:request_publication)
        model[:request_publication] = true
      end
      model.update!(attrs)

      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue Support::ImageUpload::Invalid => e
      { dropzone: nil, field_errors: [{ field: "banner", message: e.message }], errors: [e.message] }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    # The platform's moderators are told, in the dropzones they are members of (a notification belongs to a member), and
    # the dropzone's own log shows the request
    def announce_publication_request(model)
      moderators = DropzoneUser.kept.where(dropzone: model, user: User.where(moderation_role: %w(moderator administrator)))
      sender = DropzoneUser.membership(model, context[:current_resource])
      moderators.find_each do |moderator|
        Notification.create!(
          received_by: moderator,
          message: "Dropzone #{model.name} has requested publication",
          notification_type: :publication_requested,
          resource: model,
          sent_by: sender
        )
      end

      Activity::Event.create!(
        dropzone: model, resource: model, action: :updated, level: :info, access_level: :admin, created_by: sender,
        message: "#{context[:current_resource].name} requested publication of #{model.name}"
      )
    end

    def authorized?(id: nil, attributes: nil)
      dropzone = Dropzone.find(id)

      if attributes[:is_public] && dropzone.is_public != attributes[:is_public] && (User.moderation_roles[context[:current_resource].moderation_role] < User.moderation_roles["moderator"])
        return false, {
          errors: [
            "You cant modify the publication state of this dropzone",
          ],
        }
      end

      if context[:current_resource].can?(
        "updateDropzone",
        dropzone_id: id
      )
        return true
      end
      [
        false, {
          errors: [
            "You don't have permissions to edit this dropzone",
          ],
        },
      ]
    end
  end
end
