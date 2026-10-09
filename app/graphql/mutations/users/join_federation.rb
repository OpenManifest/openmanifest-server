# frozen_string_literal: true

module Mutations::Users
  class JoinFederation < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction

    field :user_federation, Types::Users::UserFederation, null: true
    argument :attributes, Types::Input::UserFederationInput, required: true
    argument :dropzone, ID, required: false,
                            description: "The dropzone to log this for, defaults to the user's latest membership (a federation belongs to the user)"

    def resolve(attributes:, dropzone: nil)
      user = context[:current_resource]
      membership = membership_for(user, dropzone)
      return refuse("You are not a member of that dropzone") if dropzone.present? && membership.nil?

      mutate(
        ::Federations::AssignUser,
        :user_federation,
        federation: attributes[:federation],
        license: attributes[:license],
        uid: attributes[:uid],
        user: user,
        # Without a membership there is no dropzone to log it for
        access_context: ::ApplicationInteraction::AccessContext.new(membership, user: user, dropzone: membership&.dropzone)
      )
    end

    private

    def membership_for(user, dropzone_id)
      memberships = user.dropzone_users.kept
      return memberships.find_by(dropzone_id: dropzone_id) if dropzone_id.present?

      memberships.order(id: :desc).first
    end

    def refuse(message)
      { user_federation: nil, field_errors: nil, errors: [message] }
    end
  end
end
