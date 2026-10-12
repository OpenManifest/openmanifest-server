# frozen_string_literal: true

class Demo::Generators::Tickets < ApplicationInteraction
  steps :create_height_ticket,
        :create_hop_n_pop_ticket,
        :create_tandem_ticket

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.operator,
      action: :created,
      access_level: :system,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "[System] Created demo tickets: Height, Hop n Pop and Tandem"
    )
  end

  def create_height_ticket
    access_context.operator.ticket_types.find_or_create_by(
      name: "Height",
      currency: "AUD",
      cost: 38,
      default_destination: destination(14_000),
      allow_manifesting_self: true,
      is_tandem: false
    )
  end

  def create_hop_n_pop_ticket
    access_context.operator.ticket_types.find_or_create_by(
      name: "Hop n Pop",
      currency: "AUD",
      cost: 25,
      default_destination: destination(4000),
      allow_manifesting_self: true,
      is_tandem: false
    )
  end

  def create_tandem_ticket
    access_context.operator.ticket_types.find_or_create_by(
      name: "Tandem",
      currency: "AUD",
      cost: 299,
      default_destination: destination(14_000),
      allow_manifesting_self: false,
      is_tandem: true
    )
  end

  private

  def destination(feet) = ::Destination.altitude_for(access_context.operator, feet)
end
