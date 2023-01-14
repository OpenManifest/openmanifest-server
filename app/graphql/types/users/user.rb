# frozen_string_literal: true

module Types::Users
  class User < Types::Base::Object
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :moderation_role, Types::Users::ModerationRole, null: true
    field :push_token, String, null: true
    field :exit_weight, String, null: true
    field :nickname, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :apf_number, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :rigs, [Types::Equipment::Rig], null: true
    field :licenses, [Types::Meta::License], null: true
    field :dropzone_users, [Types::Users::DropzoneUser], null: true
    field :user_federations, [Types::Users::UserFederation], null: true

    field :image, String, null: true, method: :avatar_url
  end
end
