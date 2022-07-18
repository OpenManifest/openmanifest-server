# frozen_string_literal: true

module Mutations::Setup::RigInspections
  class UpdateFormTemplate < Mutations::BaseMutation
    field :form_template, Types::FormTemplateType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::FormTemplateInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = FormTemplate.find(id)

      model.update!(attributes.to_h)
      {
        form_template: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        form_template: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        form_template: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        form_template: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateFormTemplate",
        dropzone_id: attributes[:dropzone_id]
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to update this form"
            ]
          }
      end
    end
  end
end
