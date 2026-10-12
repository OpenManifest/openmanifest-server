# frozen_string_literal: true

class Demo::Generators::Vehicles < ApplicationInteraction
  steps :create_vehicles

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.operator,
      action: :created,
      access_level: :system,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "[System] Created demo vehicles: Cessna C208 and Cessna C182"
    )
  end

  def create_vehicles
    access_context.operator.vehicles.find_or_create_by(
      name: "Caravan C208",
      registration: "ABC123",
      min_capacity: 6,
      capacity: 16
    )

    access_context.operator.vehicles.find_or_create_by(
      name: "C182",
      registration: "ABC123",
      min_capacity: 2,
      capacity: 5
    )
  end
end
