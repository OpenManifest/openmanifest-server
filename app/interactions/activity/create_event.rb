# frozen_string_literal: true

class Activity::CreateEvent < ApplicationInteraction
  symbol :level, default: :info
  symbol :action
  string :message
  string :details, default: ""
  symbol :access_level, default: :user
  record :dropzone
  object :resource, class: ApplicationRecord, default: nil

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
      message: message,
      details: details,
      dropzone: access_context.dropzone,
      created_by: access_context.subject
    )
  end

  def save_event
    errors.merge!(@event.errors) unless build_event.save
  end
end
