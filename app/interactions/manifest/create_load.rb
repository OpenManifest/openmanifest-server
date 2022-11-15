# frozen_string_literal: true

class Manifest::CreateLoad < ApplicationInteraction
  allow :createLoad

  string  :name,          default: ""
  integer :max_slots,     default: nil
  object  :pilot,         class: DropzoneUser, default: nil
  object  :gca,           class: DropzoneUser, default: nil
  object  :load_master,   class: DropzoneUser, default: nil
  object  :plane,         class: Plane
  string  :state,         default: "open"
  date_time :created_at,  default: -> { DateTime.current }

  steps :build_load,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @load,
      action: :created,
      access_level: :user,
      created_at: created_at,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} created load ##{@load.load_number}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      action: :created,
      created_at: created_at,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} failed to create a new load"
    )
  end

  def build_load
    @load = access_context.dropzone.loads.new(
      name: name,
      gca: gca,
      pilot: pilot,
      load_master: load_master,
      plane: plane,
      state: state,
      max_slots: max_slots || plane.max_slots,
      created_at: created_at
    )
  end

  def save
    errors.merge!(@load.errors) unless @load.save
    @load
  end
end
