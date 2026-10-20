# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261013110000_add_participant_limits")

# P7.16: the columns the limits rules read. The example goes back and forward inside its transaction.
RSpec.describe AddParticipantLimits do
  let(:connection) { ActiveRecord::Base.connection }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models = [User, TicketType, ActivityType, Vehicle].each(&:reset_column_information)

  after { reset_models }

  it "goes back without the limits" do
    quietly { described_class.new.migrate(:down) }

    expect(connection.column_exists?(:users, :date_of_birth)).to be(false)
    expect(connection.column_exists?(:ticket_types, :participant_limits)).to be(false)
    expect(connection.column_exists?(:ticket_types, :group_limits)).to be(false)
    expect(connection.column_exists?(:activity_types, :participant_limits)).to be(false)
    expect(connection.column_exists?(:vehicles, :max_payload_kg)).to be(false)
  end

  it "gives every ticket type and activity no limits" do
    operator = create(:operator)
    ticket = create(:ticket_type, operator: operator)
    quietly { described_class.new.migrate(:down) }
    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(ticket.reload).to have_attributes(participant_limits: {}, group_limits: {})
    expect(ActivityType.pluck(:participant_limits).uniq).to eq([{}])
    expect(Vehicle.pluck(:max_payload_kg).compact).to be_empty
  end
end
