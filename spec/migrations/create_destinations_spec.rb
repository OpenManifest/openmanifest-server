# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012100000_create_destinations")

# P7.8: the altitude of ticket types (feet) becomes destinations (metres). The example goes back to the old schema inside
# its transaction (PostgreSQL DDL is transactional), writes the old columns, migrates up and reads the new ones.
RSpec.describe CreateDestinations do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator) }

  def reset_models
    [TicketType, Slot, Destination, LoadDestination].each(&:reset_column_information)
  end

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  # The schema before this migration (the example's transaction rolls it back to today's at the end)
  def go_back
    quietly { described_class.new.migrate(:down) }
    reset_models
  end

  def go_forward
    quietly { described_class.new.migrate(:up) }
    reset_models
  end

  after { reset_models }

  def insert_ticket(name, altitude)
    connection.insert(<<~SQL.squish)
      INSERT INTO ticket_types (name, operator_id, altitude, created_at, updated_at)
      VALUES (#{connection.quote(name)}, #{operator.id}, #{altitude ? Integer(altitude) : 'NULL'}, NOW(), NOW())
    SQL
  end

  it "creates one destination per operator and altitude, named after the usual ones, and points the tickets at it" do
    go_back
    insert_ticket("Height", 14_000)
    insert_ticket("Tandem", 14_000)
    insert_ticket("Hop n Pop", 4000)
    insert_ticket("Wingsuit", 5000)
    insert_ticket("Free", nil)

    go_forward

    destinations = operator.destinations.order(:altitude_m).to_h { |d| [d.name, [d.kind, d.altitude_m.to_f]] }
    expect(destinations).to eq(
      "Hop n Pop" => ["altitude", 1219.2],
      "5000 ft" => ["altitude", 1524.0],
      "Full altitude" => ["altitude", 4267.2]
    )
    tickets = operator.ticket_types.to_h { |t| [t.name, t.default_destination&.name] }
    expect(tickets).to eq(
      "Height" => "Full altitude", "Tandem" => "Full altitude", "Hop n Pop" => "Hop n Pop",
      "Wingsuit" => "5000 ft", "Free" => nil
    )
    expect(connection.column_exists?(:ticket_types, :altitude)).to be(false)
  end

  it "gives existing slots the destination of their ticket type" do
    vehicle = create(:vehicle, operator: operator)
    ticket = create(:ticket_type, operator: operator, name: "Height")
    member = create(:membership, operator: operator, credits: 500)
    slot = create(:slot, load: create(:load, vehicle: vehicle), operator: operator, ticket_type: ticket, membership: member,
                         activity_type: ActivityType.allowed_for([member]).first)
    expect(slot.destination.altitude_ft).to eq(14_000)

    go_back
    go_forward

    expect(Slot.find(slot.id).destination.altitude_ft).to eq(14_000)
    expect(Slot.find(slot.id).destination).to eq(TicketType.find(ticket.id).default_destination)
  end

  it "goes back: the altitude returns to the ticket type in feet" do
    ticket = create(:ticket_type, operator: operator, name: "Height")
    go_back
    expect(connection.select_value("SELECT altitude FROM ticket_types WHERE id = #{ticket.id}")).to eq(14_000)
  end
end
