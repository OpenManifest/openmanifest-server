# frozen_string_literal: true

module Mutations::Users
  class UpdateUser < Mutations::BaseMutation
    field :membership, Types::Users::Membership, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::UserInput, required: true
    argument :membership, ID, required: false,
                              prepare: -> (value, ctx) { Membership.find_by(id: value) }

    PROFILE_ATTRIBUTES = %i(name nickname push_token image federation_number phone email license body_mass_kg).freeze

    # Only the attributes that were sent are passed on: `pushToken: null` clears the push token, leaving it out keeps it.
    # Without a member (logging out before choosing an operator) the caller updates their own profile.
    def resolve(attributes: nil, membership: nil)
      current_user = context[:current_resource]
      mutate(
        ::Users::UpdateUser,
        :membership,
        access_context: membership ? access_context_for(membership.operator_id) : ::ApplicationInteraction::AccessContext.new(nil, user: current_user),
        membership: membership,
        user: membership ? nil : current_user,
        **attributes.to_h.slice(*PROFILE_ATTRIBUTES)
      )
    end
  end
end
