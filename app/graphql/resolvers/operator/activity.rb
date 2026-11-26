# frozen_string_literal: true

class Resolvers::Operator::Activity < Resolvers::Base
  max_page_size 50

  # Event access levels and the permission that lets a member read them
  LEVEL_PERMISSIONS = {
    "user" => :viewUserActivity,
    "admin" => :viewAdminActivity,
    "system" => :viewSystemActivity,
  }.freeze

  type Types::System::Events::Event.connection_type, null: false
  description "Get all Activity Events for an operator (or all operators)"

  argument :access_levels, [Types::System::Events::EventAccessLevel], required: false
  argument :actions, [Types::System::Events::EventAction], required: false
  argument :created_by, [GraphQL::Types::ID], required: false,
                                              description: "Filter by who created the event",
                                              prepare: -> (value, ctx) { Membership.where(id: value) }
  argument :operator, [GraphQL::Types::ID], required: false,
                                            description: "Filter by Operator",
                                            prepare: -> (value, ctx) { Operator.where(id: value) }
  argument :levels, [Types::System::Events::EventLevel], required: false
  argument :time_range, Types::Input::TimeRangeInput, required: false
  def resolve(
    operator: nil,
    created_by: nil,
    levels: nil,
    actions: nil,
    access_levels: nil,
    time_range: nil
  )
    query = visible_events(operator)

    query = query.where(operator: operator)                 if operator
    query = query.where(level: levels)                      if levels
    query = query.where(access_level: access_levels)        if access_levels
    query = query.where.not(level: :debug)                  unless levels
    query = query.where(created_by: created_by)             if created_by
    query = query.where(created_at: time_range.start_time..time_range.end_time) if time_range
    query.order(created_at: :desc)
  end

  private

  # Only events of operators the caller is a member of, and only the access levels the caller's role may view there.
  # Platform moderators see everything. Asking for an operator the caller does not belong to is refused.
  def visible_events(operators)
    raise authentication_error unless current_user
    return ::Activity::Event.all if current_user.is_moderator?

    memberships = Membership.kept.where(user_id: current_user.id)
    if operators
      foreign = operators.where.not(id: memberships.select(:operator_id))
      raise forbidden("You are not a member of this operator") if foreign.exists?
      memberships = memberships.where(operator_id: operators.select(:id))
    end

    memberships.reduce(::Activity::Event.none) do |events, membership|
      levels = LEVEL_PERMISSIONS.select { |_, permission| membership.can?(permission) }.keys
      next events if levels.empty?

      events.or(::Activity::Event.where(operator_id: membership.operator_id, access_level: levels))
    end
  end
end
