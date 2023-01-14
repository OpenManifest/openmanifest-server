# frozen_string_literal: true

module Mutations::Manifest
  class CreateSlots < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction
    field :load, Types::Manifest::Load, null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      mutate(
        Manifest::CreateMultipleSlots,
        :load,
        access_context: access_context_for(
          attributes[:load].dropzone
        ),
        ticket_type: attributes[:ticket_type],
        jump_type: attributes[:jump_type],
        group_number: attributes[:group_number],
        load: attributes[:load],
        users: attributes[:user_group].map { |h| h.to_h.except(:id).merge(dropzone_user: DropzoneUser.find_by(id: h[:id])) }
      )
    end

    def authorized?(attributes: nil)
      dropzone = attributes[:load].plane.dropzone
      contains_current_user = attributes[:user_group] && attributes[:user_group].any? do |member|
        member[:id] == context[:current_resource].id
      end
      contains_others = attributes[:user_group] && attributes[:user_group].any? do |member|
        member[:id] != context[:current_resource].id
      end

      # Check if we're manifesting tandems
      manifesting_tandems = attributes[:ticket_type].is_tandem?

      # Check if the user has permissions to manifest others
      can_manifest_others = context[:current_resource].can?(:createUserSlot, dropzone_id: dropzone.id)

      if manifesting_tandems && !can_manifest_others && contains_others
        [
          false, {
            load: nil,
            field_errors: nil,
            errors: [
              "You dont have permissions to manifest other people",
            ],
          },
        ]
      elsif context[:current_resource].can?(:createUserSlot, dropzone_id: dropzone.id)
        true
      elsif context[:current_resource].can?(:createUserSlotWithSelf, dropzone_id: dropzone.id) && contains_current_user
        true
      elsif context[:current_resource].can?(:createUserSlotWithSelf, dropzone_id: dropzone.id) && contains_current_user
        [
          false, {
            errors: [
              "You can only manifest a group if you're a part of it",
            ],
          },
        ]
      else
        [
          false, {
            errors: [
              "You don't have permissions to manifest other users #{required_permission}",
            ],
          },
        ]
      end
    end
  end
end
