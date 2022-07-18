# frozen_string_literal: true

class Resolvers::Activity < Resolvers::Base
  type Types::Events::EventType.connection_type, null: false
  description "Get all Activity Events for a dropzone (or all dropzones)"


  argument :dropzone, [Int], required: true,
           description: "Filter by Dropzone",
           prepare: -> (value, ctx) { Dropzone.where(value) }
  argument :levels,  [Types::Events::EventLevelType], required: false
  argument :actions, [Types::Events::EventActionType], required: false
  argument :created_by, [Int], required: false,
           description: "Filter by who created the event",
           prepare: -> (value, ctx) { DropzoneUser.where(value) }
  def resolve(
    dropzone: nil,
    created_by: nil,
    levels: nil,
    actions: nil,
    lookahead: nil
  )
    lookahead = lookahead.selection(:edges).selection(:node)

    query = ::Activity::Event
    query = query.includes(:created_by) if lookahead.selects?(:created_by)
    query = query.where(dropzone: dropzone)                 if dropzone
    query = query.where(level: level)                       if level
    query = query.where.not(level: :debug)                  unless level
    query = query.where(created_by: created_by)             if created_by
    query.order(created_at: :desc)
  end
end
