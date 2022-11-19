# frozen_string_literal: true

class Resolvers::Dropzone < Resolvers::Base
  type Types::DropzoneType, null: true
  description "Get dropzone details"
  argument :id, GraphQL::Types::ID, required: true
  def resolve(id:, lookahead: nil)
    query = scope
    query = query.includes(:user_roles)     if lookahead.selects?(:user_roles) || lookahead.selects?(:roles)
    query = query.includes(:ticket_types)   if lookahead.selects?(:ticket_types)
    query = query.includes(:extras)         if lookahead.selects?(:extras)
    query = query.includes(:rigs)           if lookahead.selects?(:rigs)
    query = query.includes(:planes)         if lookahead.selects?(:planes)
    query = query.includes(loads: :slots)   if lookahead.selects?(:loads)
    query.find_by(id: id)
  end

  def scope
    query = Dropzone.kept.includes(:dropzone_users)
    query.where(state: :public).or(
      query.where(dropzone_users: User.first.dropzone_users.owner)
    )
  end
end
