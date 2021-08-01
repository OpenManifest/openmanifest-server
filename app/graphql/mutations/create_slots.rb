# frozen_string_literal: true

module Mutations
  class CreateSlots < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      plane_load = Load.find(attributes[:load_id])
      dropzone = plane_load.plane.dropzone

      # Get highest group number on this load
      next_group_number = (plane_load.slots.pluck(:group_number).to_a + [0]).max + 1

      # Check how many users we're manifesting, and return
      # an error if there aren't enough slots on this load
      slots_expected = attributes[:user_group].map { |user| user[:passenger_name] ? 2 : 1 }.sum

      if slots_expected > plane_load.reload.available_slots
        return {
          load: nil,
          field_errors: nil,
          errors: [
            "Only #{plane_load.available_slots} slots available"
          ]
        }
      end

      # Check if we're manifesting tandems
      manifesting_tandems = TicketType.find(attributes[:ticket_type_id]).is_tandem?

      slots = attributes[:user_group].map do |user|
        model = Slot.find_or_initialize_by(
          dropzone_user_id: user[:id],
          load_id: attributes[:load_id],
        )

        model.assign_attributes(
          attributes.to_h.except(
            :passenger_name,
            :passenger_exit_weight,
            :user_group,
            :rig_id,
          ).merge(
            rig_id: user[:rig_id],
            exit_weight: user[:exit_weight],
            # If we're editing, group_number stays the same
            group_number: model.group_number || next_group_number
          )
        )

        if model.ticket_type.is_tandem? && user[:passenger_name]
          if model.passenger_slot.present?
            model.passenger_slot.passenger.update(
              name: user[:passenger_name],
              exit_weight: user[:passenger_exit_weight],
            )
          else
            passenger = Passenger.find_or_create_by(
              name: user[:passenger_name],
              exit_weight: user[:passenger_exit_weight],
              dropzone: dropzone
            )

            model.passenger_slot = Slot.create(
              load: plane_load,
              passenger: passenger,
              exit_weight: user[:passenger_exit_weight],
              ticket_type: model.ticket_type,
              jump_type: model.jump_type,
            )
          end
        else
          puts "--TICKET"
          puts model.ticket_type
          puts model.ticket_type.is_tandem?
          puts attributes.to_h
        end

        # Show errors if the dropzone is using credits
        # and the user doesn't have the funds for this slot
        if dropzone.is_credit_system_enabled?
          # Find extras
          extra_cost = Extra.where(
            dropzone: dropzone,
            id: attributes[:extra_ids],
          ).map(&:cost).reduce(&:sum)
          extra_cost ||= 0

          cost = model.ticket_type.cost + extra_cost
          dz_user = dropzone.dropzone_users.find_by(id: user[:id])
          credits = dz_user&.credits || 0

          # Ignore costs for tandems, this is a dropzone expense paid for
          # in real life anyway. Credits not needed
          if !manifesting_tandems
            if cost > credits
              return {
                slot: nil,
                errors: ["#{dz_user.user.name} doesn't have enough credits to manifest for this jump"],
                field_errors: [
                  { field: "credits", message: "Not enough credits to manifest for this jump" }
                ],
              }
            end
          end
        end
        model
      end


      slots.map(&:save!)


      {
        load: slots.first.load.reload,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        load: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
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
