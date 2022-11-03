# frozen_string_literal: true

class Resolvers::Dropzone::Activity < Resolvers::Base
  max_page_size 50
  type Types::Events::EventType.connection_type, null: false
  description "Get all Activity Events for a dropzone (or all dropzones)"


  argument :dropzone, [GraphQL::Types::ID], required: false,
           description: "Filter by Dropzone",
           prepare: -> (value, ctx) { Dropzone.where(id: value) }
  argument :levels,  [Types::Events::EventLevelType], required: false
  argument :access_levels,  [Types::Events::EventAccessLevelType], required: false
  argument :actions, [Types::Events::EventActionType], required: false
  argument :time_range, Types::Input::TimeRangeInput, required: false
  argument :created_by, [GraphQL::Types::ID], required: false,
           description: "Filter by who created the event",
           prepare: -> (value, ctx) { DropzoneUser.where(id: value) }
  def resolve(
    dropzone: nil,
    created_by: nil,
    levels: nil,
    actions: nil,
    access_levels: nil,
    time_range: nil,
    lookahead: nil
  )
    lookahead = lookahead.selection(:edges).selection(:node)

    query = ::Activity::Event
    query = query.includes(:created_by) if lookahead.selects?(:created_by)
    query = query.where(dropzone: dropzone)                 if dropzone
    query = query.where(level: levels)                      if levels
    query = query.where(access_level: access_levels)        if access_levels
    query = query.where.not(level: :debug)                  unless levels
    query = query.where(created_by: created_by)             if created_by
    query = query.where(created_at: time_range.start_time..time_range.end_time) if time_range
    query.order(created_at: :desc)
  end
end
