# frozen_string_literal: true

module Mutations::Users
  class JoinFederation < Mutations::BaseMutation
    include Types::Interfaces::ActiveInteraction
    field :user_federation, Types::Users::UserFederation, null: true
    argument :attributes, Types::Input::UserFederationInput, required: true

    def resolve(attributes:)
      mutate(
        ::Federations::AssignUser,
        :user_federation,
        federation: attributes[:federation],
        license: attributes[:license],
        uid: attributes[:uid],
        user: context[:current_resource],
        access_context: access_context_for(
          # FIXME: Pass dropzone as variable for logging to be accurate
          context[:current_resource].dropzone_users.order(id: :desc).first.dropzone_id
        )
      )
    end
  end
end
