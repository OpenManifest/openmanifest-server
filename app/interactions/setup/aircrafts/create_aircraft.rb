# frozen_string_literal: true

class Setup::Aircrafts::CreateAircraft < ApplicationInteraction
  allow :createPlane
  string :name
  string :registration
  integer :hours, default: nil
  integer :min_slots, default: 0
  integer :max_slots, default: 4

  steps :build_aircraft,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @aircraft,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} created aircraft #{name} (#{registration})"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} failed to create aircraft #{name} (#{registration})"
    )
  end

  def build_aircraft
    @aircraft = access_context.dropzone.planes.new(
      name: name,
      registration: registration,
      min_slots: min_slots,
      max_slots: max_slots
    )
  end

  def save
    errors.merge(@aircraft.errors) unless @aircraft.save
    @aircraft
  end
end
