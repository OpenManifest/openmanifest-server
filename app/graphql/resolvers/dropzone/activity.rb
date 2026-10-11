# frozen_string_literal: true

class Resolvers::Dropzone::Activity < Resolvers::Base
  max_page_size 50

  # Event access levels and the permission that lets a member read them
  LEVEL_PERMISSIONS = {
    "user" => :viewUserActivity,
    "admin" => :viewAdminActivity,
    "system" => :viewSystemActivity,
  }.freeze

  type Types::System::Events::Event.connection_type, null: false
  description "Get all Activity Events for a dropzone (or all dropzones)"

  argument :access_levels, [Types::System::Events::EventAccessLevel], required: false
  argument :actions, [Types::System::Events::EventAction], required: false
  argument :created_by, [GraphQL::Types::ID], required: false,
                                              description: "Filter by who created the event",
                                              prepare: -> (value, ctx) { DropzoneUser.where(id: value) }
  argument :dropzone, [GraphQL::Types::ID], required: false,
                                            description: "Filter by Dropzone",
                                            prepare: -> (value, ctx) { Dropzone.where(id: value) }
  argument :levels, [Types::System::Events::EventLevel], required: false
  argument :time_range, Types::Input::TimeRangeInput, required: false
  def resolve(
    dropzone: nil,
    created_by: nil,
    levels: nil,
    actions: nil,
    access_levels: nil,
    time_range: nil,
    lookahead: nil
  )
    query = apply_lookaheads(lookahead, visible_events(dropzone))

    query = query.where(dropzone: dropzone)                 if dropzone
    query = query.where(level: levels)                      if levels
    query = query.where(access_level: access_levels)        if access_levels
    query = query.where.not(level: :debug)                  unless levels
    query = query.where(created_by: created_by)             if created_by
    query = query.where(created_at: time_range.start_time..time_range.end_time) if time_range
    query.order(created_at: :desc)
  end

  private

  # Only events of dropzones the caller is a member of, and only the access levels the caller's role may view there.
  # Platform moderators see everything. Asking for a dropzone the caller does not belong to is refused.
  def visible_events(dropzones)
    raise authentication_error unless current_user
    return ::Activity::Event.all if current_user.is_moderator?

    memberships = DropzoneUser.kept.where(user_id: current_user.id)
    if dropzones
      foreign = dropzones.where.not(id: memberships.select(:dropzone_id))
      raise forbidden("You are not a member of this dropzone") if foreign.exists?
      memberships = memberships.where(dropzone_id: dropzones.select(:id))
    end

    memberships.reduce(::Activity::Event.none) do |events, membership|
      levels = LEVEL_PERMISSIONS.select { |_, permission| membership.can?(permission) }.keys
      next events if levels.empty?

      events.or(::Activity::Event.where(dropzone_id: membership.dropzone_id, access_level: levels))
    end
  end
end
