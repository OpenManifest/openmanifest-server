# frozen_string_literal: true

class Setup::Vehicles::CreateVehicle < ApplicationInteraction
  allow :createVehicle
  string :name
  string :registration
  integer :hours, default: nil
  integer :min_capacity, default: 0
  integer :capacity, default: 4

  steps :build_vehicle,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @vehicle,
      action: :created,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} created vehicle #{name} (#{registration})"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      action: :created,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to create vehicle #{name} (#{registration})"
    )
  end

  def build_vehicle
    @vehicle = access_context.operator.vehicles.new(
      name: name,
      registration: registration,
      min_capacity: min_capacity,
      capacity: capacity
    )
  end

  def save
    errors.merge(@vehicle.errors) unless @vehicle.save
    @vehicle
  end
end
