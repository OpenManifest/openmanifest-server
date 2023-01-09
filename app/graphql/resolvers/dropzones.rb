# frozen_string_literal: true

class Resolvers::Dropzones < Resolvers::Base
  type Types::DropzoneType.connection_type, null: false
  description "Get all available dropzones"

  argument :state, [Types::Dropzone::State], required: false,
                                             default_value: nil
  def resolve(
    state: nil,
    lookahead: nil
  )
    lookahead = lookahead.selection(:edges).selection(:node)

    query = scope
    query = query.includes(:user_roles)     if lookahead.selects?(:user_roles)
    query = query.includes(:dropzone_users) if lookahead.selects?(:dropzone_users)
    query = query.includes(:ticket_types)   if lookahead.selects?(:ticket_types)
    query = query.includes(:extras)         if lookahead.selects?(:extras)
    query = query.includes(:rigs)           if lookahead.selects?(:rigs)
    query = query.includes(:planes)         if lookahead.selects?(:planes)
    query = query.includes(loads: :slots)   if lookahead.selects?(:loads)
    query = query.includes(:roles)          if lookahead.selects?(:roles)

    query.distinct.order(id: :asc)
  end

  def scope
    Dropzone.for(context[:current_resource])
  end
end
