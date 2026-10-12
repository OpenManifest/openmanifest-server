# frozen_string_literal: true

module Types::Users
  class User < Types::Base::Object
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :moderation_role, Types::Users::ModerationRole, null: true
    field :push_token, String, null: true, broadcastable: false
    field :body_mass_kg, String, null: true
    field :nickname, String, null: true
    field :email, String, null: true, broadcastable: false
    field :phone, String, null: true, broadcastable: false
    field :apf_number, String, null: true
    async_field :rigs, [Types::Equipment::Rig], null: true
    async_field :licenses, [Types::Meta::License], null: true
    async_field :memberships, [Types::Users::Membership], null: true
    async_field :user_federations, [Types::Users::UserFederation], null: true

    field :image, String, null: true, method: :avatar_url
    timestamp_fields

    # Personal data: your own, or a member's of an operator where you have readUser. nil (not an error) otherwise, so
    # lists of members still render.
    def push_token
      object.push_token if viewer_is_self?
    end

    def email
      object.email if can_read_personal_data?
    end

    def phone
      object.phone if can_read_personal_data?
    end

    private

    def viewer
      context[:current_resource]
    end

    def viewer_is_self?
      viewer.present? && viewer.id == object.id
    end

    def can_read_personal_data?
      return false unless viewer
      return true if viewer_is_self? || viewer.is_moderator?

      readable_user_ids.include?(object.id)
    end

    # Users who are members of an operator where the viewer may read user data, worked out once per request
    def readable_user_ids
      context[:readable_user_ids] ||= begin
        operator_ids = ::Membership.kept.where(user_id: viewer.id).includes(:user_role).select { |membership| membership.can?(:readUser) }.map(&:operator_id)
        ::Membership.kept.where(operator_id: operator_ids).distinct.pluck(:user_id).to_set
      end
    end
  end
end
