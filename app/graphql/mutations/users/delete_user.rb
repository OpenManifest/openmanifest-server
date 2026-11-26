# frozen_string_literal: true

module Mutations::Users
  class DeleteUser < Mutations::BaseMutation
    field :membership, Types::Users::Membership, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :id, Int, required: true,
                       description: "The ID of the operator user to delete"

    def resolve(id:)
      model = Membership.find(id)

      model.discard!

      {
        membership: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      {
        membership: nil,
        field_errors: nil,
        errors: ["Failed to archive this user"],
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        membership: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        membership: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        membership: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil)
      dz_user = Membership.find_by(id: id)
      return [false, { membership: nil, field_errors: nil, errors: ["Member not found"] }] unless dz_user

      # Members can remove themselves, staff need deleteUser at the member's operator
      if context[:current_resource].id == dz_user.user_id || context[:current_resource].can?(:deleteUser, operator_id: dz_user.operator_id)
        true
      else
        [false, { membership: nil, field_errors: nil, errors: ["You can't remove this member"] }]
      end
    end
  end
end
