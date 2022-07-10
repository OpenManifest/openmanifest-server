# frozen_string_literal: true

module Mutations::Manifest
  class CreateSlot < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      dz_user_to_manifest = DropzoneUser.find(attributes[:dropzone_user_id])
      plane_load = Load.find(attributes[:load_id])
      mutate(
        Manifest::CreateSlot,
        :slot,
        on_success: -> (slot) {
          Event.create(
            level: :info,
            message: "#{context[:current_resource].name} manifested '#{dz_user_to_manifest.user.name}' (#{dz_user_to_manifest.user.email}) on load #{plane_load.load_number}",
            resource: slot,
            action: :created,
            dropzone_id: dropzone_user.dropzone_id,
            dropzone_user: DropzoneUser.find_by(
              dropzone_id: attributes[:dropzone_id],
              user_id: context[:current_resource].id
            )
          )
        },
        **attributes.to_h.slice(
          :ticket_type_id,
          :dropzone_user_id,
          :jump_type_id,
          :exit_weight,
          :rig_id,
          :load_id,
          :extra_ids,
          :passenger_name,
          :passenger_exit_weight,
        )
      )
    end

    def authorized?(attributes: nil)
      dropzone = Load.find(attributes[:load_id]).plane.dropzone
      dz_user = context[:current_resource].dropzone_users.find_by(dropzone: dropzone)

      action = if Slot.exists?(dropzone_user_id: attributes[:dropzone_user_id], load_id: attributes[:load_id])
        "update"
      else
        "create"
      end

      if dropzone.loads_today.active.where(dropzone_user: dz_user)
        resource = if attributes[:dropzone_user_id] != dz_user.id
          "UserSlot"
        else
          "Slot"
        end

        return true if dz_user.can?("#{action}#{resource}")
        [false, {
          errors: [
            "You don't have permissions to manifest other users (missing #{"#{action}#{resource}"})"
          ]
        }]
      else
        resource = if attributes[:dropzone_user_id] != dz_user.id
          "UserDoubleSlot"
        else
          "DoubleSlot"
        end


        return true if dz_user.can?("#{action}#{resource}")
        [false, {
          errors: [
            "You don't have permissions to double-manifest (missing #{"#{action}#{resource}"})"
          ]
        }]
      end
    end
  end
end
