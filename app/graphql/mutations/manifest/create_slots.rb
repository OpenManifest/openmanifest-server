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
          attributes[:load].operator
        ),
        ticket_type: attributes[:ticket_type],
        activity_type: attributes[:activity_type],
        group_number: attributes[:group_number],
        extra_ids: attributes[:extras]&.pluck(:id),
        load: attributes[:load],
        users: attributes[:user_group].map { |h| h.to_h.except(:id, :equipment).merge(membership: Membership.find_by(id: h[:id]), equipment_ids: h[:equipment]&.pluck(:id)) }
      )
    end

    # Manifesting yourself needs createSlot; a group with other people needs createUserSlot, or createUserSlotWithSelf
    # when you are one of its members (BUG-062: this compared membership ids with the user id).
    def authorized?(attributes: nil)
      operator = attributes[:load].operator
      membership = Membership.of(operator, context[:current_resource])
      return refuse("You are not a member of this operator") unless membership

      ids = attributes[:user_group].to_a.map { |member| member[:id].to_i }
      contains_self = ids.include?(membership.id)
      contains_others = ids.any? { |id| id != membership.id }

      allowed = if contains_others
                  membership.can?(:createUserSlot) || (contains_self && membership.can?(:createUserSlotWithSelf))
                else
                  membership.can?(:createSlot)
                end
      return true if allowed

      desk_only = contains_self && membership.manifest_desk_only?(contains_others ? :createUserSlotWithSelf : :createSlot)
      refuse(if desk_only
               Membership::MANIFEST_DESK_MESSAGE
             elsif contains_others
               "You don't have permissions to manifest other people"
             else
               "You don't have permissions to manifest"
             end)
    end

    private

    def refuse(message)
      [false, { load: nil, field_errors: nil, errors: [message] }]
    end
  end
end
