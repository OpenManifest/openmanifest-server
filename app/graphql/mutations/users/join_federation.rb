# frozen_string_literal: true

module Mutations::Users
  class JoinFederation < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction

    field :user_federation, Types::Users::UserFederation, null: true
    argument :attributes, Types::Input::UserFederationInput, required: true
    argument :operator, ID, required: false,
                            description: "The operator to log this for, defaults to the user's latest membership (a federation belongs to the user)"

    def resolve(attributes:, operator: nil)
      user = context[:current_resource]
      membership = membership_for(user, operator)
      return refuse("You are not a member of that operator") if operator.present? && membership.nil?

      mutate(
        ::Federations::AssignUser,
        :user_federation,
        federation: attributes[:federation],
        license: attributes[:license],
        uid: attributes[:uid],
        user: user,
        # Without a membership there is no operator to log it for
        access_context: ::ApplicationInteraction::AccessContext.new(membership, user: user, operator: membership&.operator)
      )
    end

    private

    def membership_for(user, operator_id)
      memberships = user.memberships.kept
      return memberships.find_by(operator_id: operator_id) if operator_id.present?

      memberships.order(id: :desc).first
    end

    def refuse(message)
      { user_federation: nil, field_errors: nil, errors: [message] }
    end
  end
end
