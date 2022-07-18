# frozen_string_literal: true

class Resolvers::Dropzones < Resolvers::Base
  type Types::DropzoneType.connection_type, null: false
  description "Get all available dropzones"

  argument :requested_publication, Boolean, required: false
  argument :is_public, Boolean, required: false
  def resolve(
    requested_publication: nil,
    is_public: nil,
    lookahead: nil
  )
    lookahead = lookahead.selection(:edges).selection(:node)
    only_public_dropzones = is_public || User.moderation_roles[context[:current_resource].moderation_role] < User.moderation_roles["moderator"]
    query = Dropzone.kept
    query = query.includes(:user_roles)     if lookahead.selects?(:user_roles)
    query = query.includes(:dropzone_users) if lookahead.selects?(:dropzone_users) || only_public_dropzones
    query = query.includes(:ticket_types)   if lookahead.selects?(:ticket_types)
    query = query.includes(:extras)         if lookahead.selects?(:extras)
    query = query.includes(:rigs)           if lookahead.selects?(:rigs)
    query = query.includes(:planes)         if lookahead.selects?(:planes)
    query = query.includes(loads: :slots)   if lookahead.selects?(:loads)
    query = query.includes(:roles)          if lookahead.selects?(:roles)
    if only_public_dropzones
      query = query.where(is_public: true).or(
        query.where(
          dropzone_users: {
            id: context[:current_resource].dropzone_users.includes(:user_role).where(user_role: { name: :owner }).pluck(:id)
          }
        )
      )
    end

    query = query.where(request_publication: requested_publication) if requested_publication
    query
  end
end
