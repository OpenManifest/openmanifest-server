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
          dz_user = dropzone.dropzone_users.find_by(user_id: user[:id])
          credits = dz_user.credits || 0

          if cost > credits
            return {
              slot: nil,
              errors: ["#{dz_user.user.name} doesn't have enough credits to manifest for this jump"],
              field_errors: [
                { field: "credits", message: "Not enough credits to manifest for this jump"}
              ],
            }
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

      if context[:current_resource].can?(:createUserSlot, dropzone_id: dropzone.id)
        return true
      elsif context[:current_resource].can?(:createUserSlotWithSelf, dropzone_id: dropzone.id) && contains_current_user
        return true
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
