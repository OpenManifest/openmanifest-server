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
        user: context[:current_resource]
      )
    end
  end
end
