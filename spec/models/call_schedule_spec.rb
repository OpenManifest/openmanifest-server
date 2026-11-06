# frozen_string_literal: true

require "rails_helper"

# P7.11: the minutes of the boarding calls come from the operator, and from its template until it sets them
RSpec.describe Operator, "call schedule" do
  let(:owner) { create(:user) }
  let(:dropzone) { Setup::Operators::CreateOperator.run!(owner: owner, industry: "skydiving", name: "DZ", time_zone: "Australia/Brisbane", certification_body_ids: [CertificationBody.first.id]) }

  it "is the template's until the operator sets one" do
    expect(dropzone.call_schedule_minutes).to eq([20, 15, 10])
  end

  it "is the operator's own once set" do
    dropzone.update!(settings: { call_schedule_minutes: [30, 10] })

    expect(dropzone.reload.call_schedule_minutes).to eq([30, 10])
  end

  it "can be empty: no calls, the load departs directly" do
    dropzone.update!(settings: { call_schedule_minutes: [] })

    expect(dropzone.reload.call_schedule_minutes).to eq([])
  end

  it "takes whole minutes, longest first, up to six" do
    [[10, 15], [10, 10], [0], [-5], [15.5], ["15"], [60, 50, 40, 30, 20, 15, 10]].each do |schedule|
      dropzone.settings = { call_schedule_minutes: schedule }

      expect(dropzone).not_to be_valid, "#{schedule.inspect} should be refused"
    end
    dropzone.settings = { call_schedule_minutes: [60, 50, 40, 30, 20, 10] }
    expect(dropzone).to be_valid
  end
end
