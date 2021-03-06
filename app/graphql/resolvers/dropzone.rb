# frozen_string_literal: true

class Resolvers::Dropzone < Resolvers::Base
  type Types::DropzoneType, null: true
  description "Get dropzone details"
  argument :id, Int, required: true
  def resolve(id:, lookahead: nil)
    query = Dropzone.kept
    query = query.includes(:user_roles)     if lookahead.selects?(:user_roles) || lookahead.selects?(:roles)
    query = query.includes(:dropzone_users) if lookahead.selects?(:dropzone_users)
    query = query.includes(:ticket_types)   if lookahead.selects?(:ticket_types)
    query = query.includes(:extras)         if lookahead.selects?(:extras)
    query = query.includes(:rigs)           if lookahead.selects?(:rigs)
    query = query.includes(:planes)         if lookahead.selects?(:planes)
    query = query.includes(loads: :slots)   if lookahead.selects?(:loads)
    query.find(id)
  end
end
