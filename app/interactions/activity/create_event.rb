# frozen_string_literal: true

class Activity::CreateEvent < ApplicationInteraction
  symbol :level, default: :info
  symbol :action
  string :message
  string :details, default: ""
  symbol :access_level, default: :user
  # Events belong to an operator, nobody can see one without it: what happens outside any operator (a user joining a
  # certification body before joining an operator) is not logged
  record :operator, default: nil
  object :resource, class: ApplicationRecord, default: nil
  date_time :created_at, default: -> { DateTime.now }

  validates_inclusion_of :action, in: ::Activity::Event.actions.keys.map(&:to_sym)
  validates_inclusion_of :level, in: ::Activity::Event.levels.keys.map(&:to_sym)
  validates_inclusion_of :access_level, in: ::Activity::Event.access_levels.keys.map(&:to_sym)

  steps :build_event,
        :save_event

  def build_event
    @event = ::Activity::Event.new(
      resource: resource,
      level: level,
      action: action,
      access_level: access_level,
      message: message,
      details: details,
      created_at: created_at,
      operator: access_context.operator,
    )
    return @event unless access_context.subject.is_a?(Membership)
    @event.assign_attributes(
      created_by: access_context.subject
    )
    @event
  end

  def save_event
    return if access_context.operator.blank?

    errors.merge!(@event.errors) unless build_event.save
  end
end
