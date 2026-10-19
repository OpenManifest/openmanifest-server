# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012120000_create_crew_roles")
require Rails.root.join("db/migrate/20261013100000_generalise_escorts")

# P7.10: pilot, GCA and load master move from columns of loads to crew roles and assignments. The example goes back to
# the old schema inside its transaction, and forward again.
RSpec.describe CreateCrewRoles do
  include_context "operator"

  let(:connection) { ActiveRecord::Base.connection }
  let(:gca) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsGCA) } }
  let(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  # A ticket type's escort role (P7.15) refers to the crew roles: it goes first
  def go_down
    quietly do
      GeneraliseEscorts.new.migrate(:down)
      described_class.new.migrate(:down)
    end
  end

  def go_up
    quietly do
      described_class.new.migrate(:up)
      GeneraliseEscorts.new.migrate(:up)
    end
  end

  def reset_models = [Load, CrewRole, LoadCrewAssignment, Operator].each(&:reset_column_information)

  after { reset_models }

  it "goes back: the crew returns to the columns of the load" do
    record = create(:load, vehicle: vehicle, pilot: pilot, gca: gca)

    go_down

    row = connection.select_one("SELECT pilot_id, gca_id, load_master_id FROM loads WHERE id = #{record.id}")
    expect(row).to eq("pilot_id" => pilot.id, "gca_id" => gca.id, "load_master_id" => nil)
    expect(connection.table_exists?(:crew_roles)).to be(false)
  end

  it "goes forward: a dropzone gets the three roles, and its loads their crew" do
    record = create(:load, vehicle: vehicle, pilot: pilot, gca: gca)
    go_down
    reset_models

    go_up
    reset_models

    roles = connection.select_rows("SELECT key, scope, required FROM crew_roles WHERE operator_id = #{operator.id} ORDER BY position")
    expect(roles).to eq([["pilot", "vehicle", true], ["gca", "load", true], ["load_master", "load", false]])
    crew = connection.select_rows(<<~SQL.squish)
      SELECT crew_roles.key, load_crew_assignments.membership_id, load_crew_assignments.load_vehicle_id IS NOT NULL
      FROM load_crew_assignments JOIN crew_roles ON crew_roles.id = load_crew_assignments.crew_role_id
      WHERE load_crew_assignments.load_id = #{record.id} ORDER BY crew_roles.position
    SQL
    expect(crew).to eq([["pilot", pilot.id, true], ["gca", gca.id, false]])
    expect(connection.column_exists?(:loads, :pilot_id)).to be(false)
  end

  it "gives an operator that is not a dropzone only the roles its loads used" do
    boats = Setup::Operators::CreateOperator.run!(owner: create(:user), industry: "generic", name: "Boats", time_zone: "Australia/Brisbane")
    skipper = boats.memberships.owner.first
    boat = boats.vehicles.create!(name: "Boat", capacity: 6, kind: "vehicle")
    record = Load.create!(operator: boats, vehicle: boat)
    go_down
    connection.execute("UPDATE loads SET gca_id = #{skipper.id} WHERE id = #{record.id}")

    go_up
    reset_models

    keys = connection.select_values("SELECT key FROM crew_roles WHERE operator_id = #{boats.id}")
    expect(keys).to eq(["gca"])
  end
end
