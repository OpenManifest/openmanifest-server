# frozen_string_literal: true

module Types::Users
  class User < Types::Base::Object
    lookahead do |query|
      query = query.includes(:rigs) if selects?(:rigs)
      if selects?(:dropzone_users)
        if selection(:dropzone_users).selects?(:dropzone)
          query = query.includes(dropzone_users: :dropzone)
        else
          query = query.includes(:dropzone_users)
        end
      end

      if selects?(:user_federations)
        subselections = []
        subselections << :license if selection(:user_federations).selects?(:license)
        subselections << :federation if selection(:user_federations).selects?(:federation)

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
    field :email, String, null: true, broadcastable: false
    field :phone, String, null: true, broadcastable: false
    field :apf_number, String, null: true
    field :rigs, [Types::Equipment::Rig], null: true
    field :licenses, [Types::Meta::License], null: true
    field :dropzone_users, [Types::Users::DropzoneUser], null: true
    field :user_federations, [Types::Users::UserFederation], null: true

    field :image, String, null: true, method: :avatar_url
    timestamp_fields

    # Personal data: your own, or a member's of a dropzone where you have readUser. nil (not an error) otherwise, so
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

    # Users who are members of a dropzone where the viewer may read user data, worked out once per request
    def readable_user_ids
      context[:readable_user_ids] ||= begin
        dropzone_ids = ::DropzoneUser.kept.where(user_id: viewer.id).includes(:user_role).select { |membership| membership.can?(:readUser) }.map(&:dropzone_id)
        ::DropzoneUser.kept.where(dropzone_id: dropzone_ids).distinct.pluck(:user_id).to_set
      end
    end
  end
end
