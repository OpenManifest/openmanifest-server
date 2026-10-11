# frozen_string_literal: true

require "rails_helper"

# BUG-035: the load state may only change through the state machine. BUG-026: landing counts the jumps exactly once.
RSpec.describe Load, "state machine" do
  include_context "dropzone_with_load"

  # Every event with the states it may start from
  events = {
    dispatch: %w(open),
    take_off: %w(open boarding_call),
    mark_as_landed: %w(open boarding_call in_flight),
    cancel: %w(open boarding_call),
    reopen: %w(boarding_call in_flight landed cancelled),
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

    it "does not dispatch without a time" do
      load.update_columns(dispatch_at: nil, state: Load.states["open"])

      expect(load.can_dispatch?).to be(false)
    end

    it "moves the load to the matching state" do
      load.dispatch
      expect(load.reload.state).to eq("boarding_call")
      load.take_off
      expect(load.reload.state).to eq("in_flight")
      load.mark_as_landed
      expect(load.reload.state).to eq("landed")
      load.reopen
      expect(load.reload.state).to eq("open")
    end

    it "refuses an invalid transition without changing the load" do
      load.update_column(:state, Load.states["landed"])

      expect(load.cancel).to be(false)
      expect(load.reload.state).to eq("landed")
    end
  end

  describe "jump counters" do
    let(:ticket_type) { create(:ticket_type, dropzone: dropzone, cost: 10) }
    let(:jumper) { create(:dropzone_user, dropzone: dropzone, credits: 100, jump_count: 0) }
    let!(:slot) do
      create(:slot, load: load, dropzone: dropzone, dropzone_user: jumper, ticket_type: ticket_type,
                    jump_type: JumpType.allowed_for([jumper]).first)
    end

    def counts
      [jumper.reload.jump_count, jumper.user.reload.jump_count, jumper.user.dropzone_count]
    end

    it "counts the jump once when the load lands" do
      expect { load.mark_as_landed }.to change { counts }.from([0, 0, 0]).to([1, 1, 1])
    end

    it "does not count again when the landed load is saved or landed again" do
      load.mark_as_landed
      load.update!(name: "Landed")
      load.mark_as_landed

      expect(counts).to eq([1, 1, 1])
    end

    it "takes the jump back when the load is reopened" do
      load.mark_as_landed

      expect { load.reopen }.to change { counts }.from([1, 1, 1]).to([0, 0, 0])
    end

    it "does not count a jump for a load that is cancelled" do
      expect { load.cancel }.not_to(change { counts })
    end

    it "keeps the dropzone count of a returning jumper" do
      jumper.update!(jump_count: 5)
      jumper.user.update!(jump_count: 5, dropzone_count: 1)

      expect { load.mark_as_landed }.to change { counts }.from([5, 5, 1]).to([6, 6, 1])
    end
  end

  describe "notifications" do
    let(:jumper) { create(:dropzone_user, dropzone: dropzone, credits: 100) }
    let!(:slot) do
      create(:slot, load: load, dropzone: dropzone, dropzone_user: jumper, ticket_type: create(:ticket_type, dropzone: dropzone, cost: 10),
                    jump_type: JumpType.allowed_for([jumper]).first)
    end

    it "tells the jumpers about the boarding call" do
      expect { load.dispatch }.to change { Notification.where(notification_type: :boarding_call, received_by: jumper).count }.by(1)
    end

    it "tells the jumpers when the load is cancelled" do
      expect { load.cancel }.to change { Notification.where(notification_type: :boarding_call_canceled, received_by: jumper).count }.by(1)
    end
  end
end
