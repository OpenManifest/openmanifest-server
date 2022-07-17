# frozen_string_literal: true

module Mutations::Setup::Tickets
  class CreateExtra < Mutations::BaseMutation
    field :extra, Types::ExtraType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::ExtraInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = find_or_build_model(id)
      model.attributes = attributes.to_h

      model.save!

      ::Activity::Event.create(
        level: :info,
        message: "A new Ticket add-on  #{model.name} was created by #{context[:current_resource].name}",
        resource: model,
        action: :created,
        dropzone_id: attributes[:dropzone_id],
        created_by: DropzoneUser.find_by(
          dropzone_id: attributes[:dropzone_id],
          user_id: context[:current_resource].id
        )
      )

      unless attributes[:extra_ids].nil?
        ::TicketTypeExtra.create(
          Extra.where(id: attributes[:extra_ids]).map do |e|
            { extra: model, ticket_type_id: e }
          end
        )
      end

      {
        extra: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        extra: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        extra: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        extra: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil, id: nil)
      if context[:current_resource].can?(
        "createExtra",
        dropzone_id: attributes[:dropzone_id]
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create ticket addons"
            ]
          }
      end
    end

    def find_or_build_model(id)
      if id
        Extra.find(id)
      else
        Extra.new
      end
    end
  end
end
