# frozen_string_literal: true

module Types::Users
  class UserFederation < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :uid, String, null: true,
                        description: "User Federation ID, e.g APF number"
    async_field :federation, Types::Meta::Federation, null: false
    async_field :license, Types::Meta::License, null: true
    async_field :user, Types::Users::User, null: false
    field :qualifications, [Types::Users::UserQualification], null: true
    def qualifications
      object.user_federation_qualifications
    end
  end
end
