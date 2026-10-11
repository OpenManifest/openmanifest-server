# frozen_string_literal: true

module Mutations::Setup::Operators
  class DeleteOperator < Mutations::BaseMutation
    field :operator, Types::OperatorType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Operator.kept.find(id)

      model.discard

      {
        operator: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        operator: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this aircraft"],
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        operator: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        operator: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        operator: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      operator = Operator.find_by(id: id)
      return [false, { errors: ["Operator not found"] }] unless operator

      if context[:current_resource].can?(:deleteOperator, operator_id: operator.id)
        true
      else
        [
          false, {
            errors: ["You cant delete this operator"],
          },
        ]
      end
    end
  end
end
