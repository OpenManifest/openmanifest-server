# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261013120000_add_booking_seam")

# P7.17: loads keep when they left and landed, slots can be prepaid. Going back and forward, with the old rows given values.
RSpec.describe AddBookingSeam do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator) }
  let(:vehicle) { create(:vehicle, operator: operator) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models = [Load, Slot].each(&:reset_column_information)

  after { reset_models }

  it "goes back without the columns" do
    quietly { described_class.new.migrate(:down) }

    expect(connection.column_exists?(:loads, :departed_at)).to be(false)
    expect(connection.column_exists?(:loads, :completed_at)).to be(false)
    expect(connection.column_exists?(:slots, :prepaid)).to be(false)
  end

  it "gives a load that has landed the time of its last change, and a slot of an escort's ticket as prepaid" do
    landed = create(:load, vehicle: vehicle)
    open_load = create(:load, vehicle: vehicle)
    member = create(:membership, operator: operator, credits: 500)
    plain = create(:slot, load: open_load, membership: member, operator: operator, activity_type: ActivityType.allowed_for([member]).first)
    tandem_ticket = create(:ticket_type, operator: operator, name: "Tandem", requires_escort: true)
    other = create(:membership, operator: operator, credits: 500)
    tandem = create(:slot, load: open_load, membership: other, operator: operator, ticket_type: tandem_ticket, activity_type: ActivityType.allowed_for([other]).first)
    quietly { described_class.new.migrate(:down) }
    connection.execute("UPDATE loads SET state = 3, updated_at = '2026-09-01 10:00:00' WHERE id = #{landed.id}")

    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(Load.find(landed.id)).to have_attributes(departed_at: Time.utc(2026, 9, 1, 10), completed_at: Time.utc(2026, 9, 1, 10))
    expect(Load.find(open_load.id)).to have_attributes(departed_at: nil, completed_at: nil)
    expect(Slot.find(tandem.id)).to be_prepaid
    expect(Slot.find(plain.id)).not_to be_prepaid
  end
end
