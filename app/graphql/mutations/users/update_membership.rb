# frozen_string_literal: true

module Mutations::Users
  class UpdateMembership < Mutations::BaseMutation
    field :membership, Types::Users::Membership, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::MembershipInput, required: true
    argument :membership, ID, required: false,
                              prepare: -> (value, ctx) { Membership.find_by(id: value) }

    # What staff can change on a membership; the member's profile (name, email, ...) is updateUser's
    UPDATABLE = %i(expires_at credits_cents user_role_id).freeze

    def resolve(membership:, attributes: nil)
      attrs = attributes.to_h.slice(*UPDATABLE)
      attrs[:expires_at] = Time.zone.at(attrs[:expires_at]) if attrs[:expires_at]
      membership.assign_attributes(attrs)
      membership.save!

      {
        membership: membership,
        errors: nil,
        field_errors: nil,
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

    # Staff with updateUser at the member's operator. A role is changed only to a role of that operator below the
    # caller's own, for a member whose own role is below the caller's too (a manager cannot demote the owner).
    def authorized?(membership: nil, attributes: nil)
      return refuse("Member not found") unless membership

      acting = Membership.of(membership.operator, context[:current_resource])
      return refuse("You don't have permission to update this") unless acting&.can?(:updateUser)

      role_id = attributes&.[](:user_role_id)
      return true if role_id.nil? || role_id == membership.user_role_id

      return refuse("That role does not belong to this operator") unless membership.operator.user_roles.exists?(id: role_id)

      assignable = acting.can?(:grantPermission) && role_id < acting.user_role_id && membership.user_role_id < acting.user_role_id
      assignable ? true : refuse("You don't have permissions to assign this role")
    end

    private

    def refuse(message)
      [false, { membership: nil, field_errors: nil, errors: [message] }]
    end
  end
end
