# frozen_string_literal: true

require "rails_helper"

# BUG-035: the load state may only change through the state machine. BUG-026: landing counts the jumps exactly once.
RSpec.describe Load, "state machine" do
  include_context "operator_with_load"

  # Every event with the states it may start from
  events = {
    call: %w(open),
    depart: %w(open boarding),
    complete: %w(open boarding departed),
    cancel: %w(open boarding),
    reopen: %w(boarding departed completed cancelled),
  }
  states = Load.states.keys

  before { load.update!(dispatch_at: 10.minutes.from_now) }

  describe "transitions" do
    events.each do |event, allowed_from|
      states.each do |from|
        expectation = allowed_from.include?(from) ? "can" : "cannot"
        it "#{expectation} #{event} from #{from}" do
          load.update_column(:state, Load.states[from])

          expect(load.public_send(:"can_#{event}?")).to eq(allowed_from.include?(from))
        end
      end
    end

    it "does not call without a time" do
      load.update_columns(dispatch_at: nil, state: Load.states["open"])

      expect(load.can_call?).to be(false)
    end

    it "moves the load to the matching state" do
      load.call
      expect(load.reload.state).to eq("boarding")
      load.depart
      expect(load.reload.state).to eq("departed")
      load.complete
      expect(load.reload.state).to eq("completed")
      load.reopen
      expect(load.reload.state).to eq("open")
    end

    it "refuses an invalid transition without changing the load" do
      load.update_column(:state, Load.states["completed"])

      expect(load.cancel).to be(false)
      expect(load.reload.state).to eq("completed")
    end
  end

  describe "jump counters" do
    let(:ticket_type) { create(:ticket_type, operator: operator, cost: 10) }
    let(:jumper) { create(:membership, operator: operator, credits: 100, load_count: 0) }
    let!(:slot) do
      create(:slot, load: load, operator: operator, membership: jumper, ticket_type: ticket_type,
                    activity_type: ActivityType.allowed_for([jumper]).first)
    end

    def counts
      [jumper.reload.load_count, jumper.user.reload.load_count, jumper.user.operator_count]
    end

    it "counts the jump once when the load lands" do
      expect { load.complete }.to change { counts }.from([0, 0, 0]).to([1, 1, 1])
    end

    it "does not count again when the completed load is saved or completed again" do
      load.complete
      load.update!(name: "Completed")
      load.complete

      expect(counts).to eq([1, 1, 1])
    end

    it "takes the jump back when the load is reopened" do
      load.complete

      expect { load.reopen }.to change { counts }.from([1, 1, 1]).to([0, 0, 0])
    end

    it "does not count a jump for a load that is cancelled" do
      expect { load.cancel }.not_to(change { counts })
    end

    it "keeps the operator count of a returning jumper" do
      jumper.update!(load_count: 5)
      jumper.user.update!(load_count: 5, operator_count: 1)

      expect { load.complete }.to change { counts }.from([5, 5, 1]).to([6, 6, 1])
    end
  end

  describe "notifications" do
    let(:jumper) { create(:membership, operator: operator, credits: 100) }
    let!(:slot) do
      create(:slot, load: load, operator: operator, membership: jumper, ticket_type: create(:ticket_type, operator: operator, cost: 10),
                    activity_type: ActivityType.allowed_for([jumper]).first)
    end

    it "tells the jumpers about the boarding call" do
      expect { load.call }.to change { Notification.where(notification_type: :boarding, received_by: jumper).count }.by(1)
    end

    it "tells the jumpers when the load is cancelled" do
      expect { load.cancel }.to change { Notification.where(notification_type: :boarding_canceled, received_by: jumper).count }.by(1)
    end
  end
end
