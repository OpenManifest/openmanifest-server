# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261013100000_generalise_escorts")

# P7.15: tandem becomes "requires an escort"; the escort's slot pointed at the guest's (`guest_slot_id`), now the guest's
# slot points at the escort's (`escort_slot_id`). The example goes back to the old columns inside its transaction, writes
# old rows, migrates forward and reads the new ones.
RSpec.describe GeneraliseEscorts do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator, lat: nil, lng: nil) }
  let(:vehicle_load) { create(:load, vehicle: create(:vehicle, operator: operator)) }
  let(:ticket) { create(:ticket_type, operator: operator) }
  let(:escort) { create(:membership, operator: operator) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models
    [Slot, TicketType, Guest].each(&:reset_column_information)
  end

  after { reset_models }

  def slot_row(**columns)
    names = %w(load_id ticket_type_id created_at updated_at) + columns.keys.map(&:to_s)
    values = [vehicle_load.id, ticket.id, "NOW()", "NOW()"] + columns.values.map { |value| connection.quote(value) }
    connection.insert("INSERT INTO slots (#{names.join(', ')}) VALUES (#{values.join(', ')})")
  end

  # A tandem as it was stored: the escort's slot points at the passenger's
  def old_tandem
    [ticket, escort, vehicle_load]
    quietly { described_class.new.migrate(:down) }
    reset_models
    connection.execute("UPDATE ticket_types SET is_tandem = TRUE WHERE id = #{ticket.id}")
    guest_slot = slot_row
    escort_slot = slot_row(membership_id: escort.id, guest_slot_id: guest_slot)
    [escort_slot, guest_slot]
  end

  it "goes back to is_tandem and the escort's guest_slot_id" do
    quietly { described_class.new.migrate(:down) }
    reset_models

    expect(connection.column_exists?(:ticket_types, :is_tandem)).to be true
    expect(connection.column_exists?(:ticket_types, :requires_escort)).to be false
    expect(connection.column_exists?(:slots, :guest_slot_id)).to be true
    expect(connection.column_exists?(:slots, :escort_slot_id)).to be false
    expect(connection.column_exists?(:guests, :email)).to be false
  end

  it "makes a tandem ticket require an escort, for one guest" do
    old_tandem

    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(ticket.reload).to have_attributes(requires_escort: true, escort_capacity: 1, escort_qualification_id: nil, escort_crew_role_id: nil)
  end

  it "points the guest's slot at the escort's slot" do
    escort_slot, guest_slot = old_tandem

    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(Slot.find(guest_slot).escort_slot_id).to eq(escort_slot)
    expect(Slot.find(escort_slot).escort_slot_id).to be_nil
    expect(Slot.find(escort_slot).guest_slots.pluck(:id)).to eq([guest_slot])
    expect(connection.column_exists?(:slots, :guest_slot_id)).to be false
  end

  it "keeps the first guest of an escort when it goes back" do
    [escort, vehicle_load, ticket]
    escort_slot = slot_row(membership_id: escort.id)
    first = slot_row(escort_slot_id: escort_slot)
    slot_row(escort_slot_id: escort_slot)

    quietly { described_class.new.migrate(:down) }
    reset_models

    expect(connection.select_value("SELECT guest_slot_id FROM slots WHERE id = #{escort_slot}")).to eq(first)
  ensure
    quietly { described_class.new.migrate(:up) } unless connection.column_exists?(:slots, :escort_slot_id)
  end

  it "gives a guest the personal fields of a booking participant" do
    quietly { described_class.new.migrate(:down) }
    quietly { described_class.new.migrate(:up) }
    reset_models

    guest = Guest.create!(operator: operator, name: "Pat", email: "pat@example.com", phone: "0400", date_of_birth: Date.new(2000, 1, 2), emergency_contact: "Sam")

    expect(guest.reload).to have_attributes(email: "pat@example.com", date_of_birth: Date.new(2000, 1, 2), emergency_contact: "Sam")
  end
end
