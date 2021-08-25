# frozen_string_literal: true

module Mutations
  class CreateSlots < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :load, Types::LoadType, null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      mutate(
        Manifest::CreateMultipleSlots,
        :load,
        ticket_type_id: attributes[:ticket_type_id],
        jump_type_id: attributes[:jump_type_id],
        load_id: attributes[:load_id],
        users: attributes[:user_group].map { |h| h.to_h.except(:id).merge(dropzone_user_id: h[:id]) }
      )
    end

    def authorized?(attributes: nil)
      dropzone = Load.find(attributes[:load_id]).plane.dropzone
      contains_current_user = attributes[:user_group] && attributes[:user_group].any? { |member| member[:id] == context[:current_resource].id }
      contains_others = attributes[:user_group] && attributes[:user_group].any? { |member| member[:id] != context[:current_resource].id }

      # Check if we're manifesting tandems
      manifesting_tandems = TicketType.find(attributes[:ticket_type_id]).is_tandem?

      # Check if the user has permissions to manifest others
      can_manifest_others = context[:current_resource].can?(:createUserSlot, dropzone_id: dropzone.id)


      if manifesting_tandems && !can_manifest_others && contains_others
        return false, {
          load: nil,
          field_errors: nil,
          errors: [
            "You dont have permissions to manifest other people"
          ]
        }
      elsif context[:current_resource].can?(:createUserSlot, dropzone_id: dropzone.id)
        true
      elsif context[:current_resource].can?(:createUserSlotWithSelf, dropzone_id: dropzone.id) && contains_current_user
        true
      elsif context[:current_resource].can?(:createUserSlotWithSelf, dropzone_id: dropzone.id) && contains_current_user
        return false, {
          errors: [
            "You can only manifest a group if you're a part of it"
          ]
        }
      else
        return false, {
          errors: [
            "You don't have permissions to manifest other users #{required_permission}"
            ]
          }
      end
    end
  end
end
