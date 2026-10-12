# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012110000_create_load_vehicles")
require Rails.root.join("db/migrate/20261012120000_create_crew_roles")

# P7.9: the vehicle of a load moves from loads.vehicle_id to load_vehicles. The example goes back to the old schema inside
# its transaction (PostgreSQL DDL is transactional), and forward again.
RSpec.describe CreateLoadVehicles do
  include_context "operator"

  let(:connection) { ActiveRecord::Base.connection }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models = [Load, Slot, LoadVehicle, CrewRole, LoadCrewAssignment].each(&:reset_column_information)

  # The crew roles of P7.10 name the vehicles of a load: they go first
  def go_down
    quietly do
      CreateCrewRoles.new.migrate(:down)
      described_class.new.migrate(:down)
    end
  end

  def go_up
    quietly do
      described_class.new.migrate(:up)
      CreateCrewRoles.new.migrate(:up)
    end
  end

  after { reset_models }

  it "goes back: the first vehicle that carries returns to the load" do
    other = create(:vehicle, operator: operator)
    operator.update!(modules: { multi_vehicle: true })
    record = create(:load, vehicle: other)
    record.update!(vehicle_roles: [{ vehicle: vehicle, role: "support" }, { vehicle: other, role: "carrying" }])

    go_down
    reset_models

    expect(connection.select_value("SELECT vehicle_id FROM loads WHERE id = #{record.id}")).to eq(other.id)
    expect(connection.table_exists?(:load_vehicles)).to be(false)
  end

  it "goes forward: every load gets its vehicle as the one that carries" do
    record = create(:load, vehicle: vehicle)
    go_down
    reset_models

    go_up
    reset_models

    rows = connection.select_rows("SELECT vehicle_id, role, position FROM load_vehicles WHERE load_id = #{record.id}")
    expect(rows).to eq([[vehicle.id, "carrying", 0]])
    expect(connection.column_exists?(:loads, :vehicle_id)).to be(false)
  end
end
