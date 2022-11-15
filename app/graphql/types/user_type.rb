# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    implements Types::AnyResourceType

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :moderation_role, Types::ModerationRoleType, null: true
    field :push_token, String, null: true
    field :exit_weight, String, null: true
    field :nickname, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :apf_number, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :rigs, [Types::RigType], null: true
    field :licenses, [Types::LicenseType], null: true
    field :dropzone_users, [Types::DropzoneUserType], null: true
    field :user_federations, [Types::UserFederationType], null: true

    field :image, String, null: true
    def image
      return nil unless object.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(object.avatar)
    rescue
      nil
    end
  end
end
