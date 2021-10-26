# frozen_string_literal: true

module Mutations
  class JoinFederation < Mutations::BaseMutation
    include Types::InteractionMutationInterface
    field :user_federation, Types::UserFederationType, null: true
    argument :attributes, Types::Input::UserFederationInput, required: true

    def resolve(attributes:)
      mutate(
        ::Federations::AssignUser,
        :user,
        federation: Federation.find(attributes[:federation_id]),
        license_id: attributes[:license_id],
        uid: attributes[:uid],
        user: context[:current_resource]
      )
    end
  end
end
