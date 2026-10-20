# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261013130000_add_called_at_to_loads")

# UB.3: the call time of a load. Loads that are boarding when it runs get the time of their last change.
RSpec.describe AddCalledAtToLoads do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator) }
  let(:vehicle) { create(:vehicle, operator: operator) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  after { Load.reset_column_information }

  it "goes back without the column" do
    quietly { described_class.new.migrate(:down) }

    expect(connection.column_exists?(:loads, :called_at)).to be(false)
  end

  it "gives a load that is boarding the time of its last change, and no other" do
    boarding = create(:load, vehicle: vehicle)
    open_load = create(:load, vehicle: vehicle)
    quietly { described_class.new.migrate(:down) }
    connection.execute("UPDATE loads SET state = 1, updated_at = '2026-10-01 09:30:00' WHERE id = #{boarding.id}")

    quietly { described_class.new.migrate(:up) }
    Load.reset_column_information

    expect(Load.find(boarding.id).called_at).to eq(Time.utc(2026, 10, 1, 9, 30))
    expect(Load.find(open_load.id).called_at).to be_nil
  end
end
