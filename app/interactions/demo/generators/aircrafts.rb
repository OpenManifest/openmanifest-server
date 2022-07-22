# frozen_string_literal: true

class Demo::Generators::Aircrafts < ApplicationInteraction
  steps :create_aircrafts

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.dropzone,
      action: :created,
      access_level: :system,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "[System] Created demo aircrafts: Cessna C208 and Cessna C182"
    )
  end


  def create_aircrafts
    access_context.dropzone.planes.find_or_create_by(
      name: "Caravan C208",
      registration: "ABC123",
      min_slots: 6,
      max_slots: 16
    )

    access_context.dropzone.planes.find_or_create_by(
      name: "C182",
      registration: "ABC123",
      min_slots: 2,
      max_slots: 5
    )
  end
end
