# frozen_string_literal: true

module Types
  class UserFederationType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :federation, Types::FederationType, null: false
    field :license, Types::LicenseType, null: true
    field :uid, Integer, null: true,
    description: 'User Federation ID, e.g APF number'
    field :qualifications, [Types::UserQualificationType], null: true
    def qualifications
      object.user_federation_qualifications
    end
  end
end
