# frozen_string_literal: true

module Types::Users
  class User < Types::Base::Object
    lookahead do |query|
      query = query.includes(:rigs) if lookahead.selects?(:rigs)
      if lookahead.selects?(:dropzone_users)
        if lookahead.selection(:dropzone_users).selects?(:dropzone)
          query = query.includes(dropzone_users: :dropzone)
        else
          query = query.includes(:dropzone_users)
        end
      end

      if lookahead.selects?(:user_federations)
        subselections = []
        subselections << :license if lookahead.selection(:user_federations).selects?(:license)
        subselections << :federation if lookahead.selection(:user_federations).selects?(:federation)

        if subselections.empty?
          query = query.includes(:user_federations)
        else
          query = query.includes(user_federations: subselections)
        end
      end
      query
    end
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
    field :rigs, [Types::Equipment::Rig], null: true
    field :licenses, [Types::Meta::License], null: true
    field :dropzone_users, [Types::Users::DropzoneUser], null: true
    field :user_federations, [Types::Users::UserFederation], null: true

    field :image, String, null: true, method: :avatar_url
    timestamp_fields
  end
end
