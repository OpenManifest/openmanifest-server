# frozen_string_literal: true

module Mutations
  class CreateSlot < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      mutate(
        Manifest::CreateSlot,
        :slot,
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

      if dropzone.loads_today.active.where(dropzone_user: dz_user)
        required_permission = if attributes[:dropzone_user_id] != dz_user.id
          "createUserSlot"
        else
          "createSlot"
        end

        return true if dz_user.can?(required_permission)
        [false, {
          errors: [
            "You don't have permissions to manifest other users (missing #{required_permission})"
          ]
        }]
      else
        required_permission = if attributes[:dropzone_user_id] != dz_user.id
          "createUserDoubleSlot"
        else
          "createDoubleSlot"
        end


        return true if dz_user.can?(required_permission)
        [false, {
          errors: [
            "You don't have permissions to double-manifest (missing #{required_permission})"
          ]
        }]
      end
    end
  end
end
