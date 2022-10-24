# frozen_string_literal: true

module Mutations::Users
  class JoinFederation < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :user_federation, Types::UserFederationType, null: true
    argument :attributes, Types::Input::UserFederationInput, required: true

    def resolve(attributes:)
      mutate(
        ::Federations::AssignUser,
        :user,
        federation: attributes[:federation],
        license: attributes[:license],
        uid: attributes[:uid],
        user: context[:current_resource],
        access_context: access_context_for(
          # FIXME: Pass dropzone as variable for logging to be accurate
          current_resource.dropzonen_users.order(id: :desc).first.dropzone_id
        )
      )
    end
  end
end
