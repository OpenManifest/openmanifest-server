# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class UpdateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::DropzoneInput, required: true
    argument :dropzone, ID, required: true,
                            prepare: -> (value, ctx) { Dropzone.find_by(id: value) }

    def resolve(attributes:, dropzone:)
      mutate(
        ::Setup::Dropzones::UpdateDropzone,
        :dropzone,
        access_context: access_context_for(dropzone),
        name: attributes[:name],
        banner: attributes[:banner],
        location: attributes[:location],
        primary_color: attributes[:primary_color],
        secondary_color: attributes[:secondary_color],
        settings: attributes.to_h[:settings],
      )
      # if attrs[:request_publication] && !model.is_public
      #   # Send a notification to administrators
      #   User.where(moderation_role: "administrator").each do |user|
      #     Notification.create(
      #       received_by: user,
      #       message: "Dropzone #{model.name} has requested publication",
      #       notification_type: :publication_requested,
      #       resource: model,
      #       sent_by: model.dropzone_users.find_by(user_id: context[:current_resource].id)
      #     )
      #   end
      # end
    end

    def authorized?(dropzone: nil, attributes: nil)
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
