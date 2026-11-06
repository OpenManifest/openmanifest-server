# frozen_string_literal: true

require "rails_helper"

# UB.3: "called at 12:10"
RSpec.describe "Load#called_at" do
  let(:operator) { create(:operator) }
  let(:vehicle) { create(:vehicle, operator: operator) }
  let(:pilot) { create(:membership, operator: operator) }
  let(:gca) { create(:membership, operator: operator) }
  let!(:load) { create(:load, vehicle: vehicle, pilot: pilot, gca: gca) }

  it "is empty while the load is open" do
    expect(load.called_at).to be_nil
  end

  it "is the time the load was called" do
    freeze_time do
      load.update!(dispatch_at: 10.minutes.from_now)
      load.call!

      expect(load.reload.called_at).to eq(Time.current)
    end
  end

  it "stays when the load takes off or lands" do
    load.update!(dispatch_at: 10.minutes.from_now)
    load.call!
    called = load.reload.called_at

    load.depart!
    expect(load.reload.called_at).to eq(called)
    load.complete!
    expect(load.reload.called_at).to eq(called)
  end

  it "is cleared when the call is cancelled" do
    load.update!(dispatch_at: 10.minutes.from_now)
    load.call!

    load.reopen!

    expect(load.reload).to have_attributes(state: "open", called_at: nil)
  end

  it "is cleared when a load that is called is cancelled" do
    load.update!(dispatch_at: 10.minutes.from_now)
    load.call!

    load.cancel!

    expect(load.reload.called_at).to be_nil
  end

  it "is the time of the new call after a call was cancelled" do
    load.update!(dispatch_at: 10.minutes.from_now)
    load.call!
    load.reopen!

    travel_to(15.minutes.from_now) { load.call! }

    expect(load.reload.called_at).to be_within(2.seconds).of(15.minutes.from_now)
  end

  it "is cleared when a landed load is reopened" do
    load.update!(dispatch_at: 10.minutes.from_now)
    load.call!
    load.complete!

    load.reopen!

    expect(load.reload.called_at).to be_nil
  end
end
