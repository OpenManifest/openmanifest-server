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
        ticket_type_id: attributes[:ticket_type_id],
        dropzone_user_id: attributes[:dropzone_user_id],
        jump_type_id: attributes[:jump_type_id],
        exit_weight: attributes[:exit_weight],
        rig_id: attributes[:rig_id],
        load_id: attributes[:load_id],
        extra_ids: attributes[:extra_ids],
        passenger_name: attributes[:passenger_name],
        passenger_exit_weight: attributes[:passenger_exit_weight]
      )
    end

    def authorized?(attributes: nil)
      dropzone = Load.find(attributes[:load_id]).plane.dropzone
      dz_user = context[:current_resource].dropzone_users.find_by(dropzone: dropzone)

      required_permission = if attributes[:dropzone_user_id] != dz_user.id
                              'createUserSlot'
                            else
                              'createSlot'
                            end

      if dz_user.can?(required_permission)
        true
      else
        [false, {
          errors: [
            "You don't have permissions to manifest other users (missing #{required_permission})"
          ]
        }]
      end
    end
  end
end
