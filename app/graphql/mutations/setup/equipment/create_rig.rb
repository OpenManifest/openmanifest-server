# frozen_string_literal: true

module Mutations::Setup::Equipment
  class CreateRig < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :rig, Types::Equipment::Rig, null: true

    argument :attributes, Types::Input::RigInput, required: true

    def resolve(attributes:)
      model = if attributes[:user_id]
                User.find(attributes[:user_id]).rigs.new
              else
                Dropzone.find(attributes[:dropzone_id]).rigs.new
      end

      attrs = attributes.to_h.except(:packing_card)

      if attrs.key?(:repack_expires_at)
        attrs[:repack_expires_at] = Time.at(attrs[:repack_expires_at])
      end
      model.assign_attributes(attrs)

      model.save!
      if attributes[:packing_card]
        model.packing_card.attach(data: image)
        model.packing_card.variant(resize_to_limit: [1920, 1920])
      end

      {
        rig: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        rig: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        rig: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(attributes: nil)
      if attributes[:user_id] && attributes[:user_id] != context[:current_resource].id
        [
          false, {
            errors: [
              "You can't create rigs for other users",
            ],
          },
        ]
      elsif attributes[:dropzone_id] && !context[:current_resource].can?("createRig", dropzone_id: attributes[:dropzone_id])
        [
          false, {
            errors: [
              "You can't create rigs for this dropzone",
            ],
          },
        ]
      else
        true
      end
    end
  end
end
