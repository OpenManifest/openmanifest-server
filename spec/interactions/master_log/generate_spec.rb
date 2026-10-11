# frozen_string_literal: true

require "rails_helper"

RSpec.describe MasterLog::Generate do
  let(:dropzone) { create(:dropzone, time_zone: "Australia/Brisbane") }

  it "creates the entry of a date with its date and stored JSON" do
    entry = described_class.run!(dropzone: dropzone, date: Date.new(2026, 10, 1))

    expect(entry).to have_attributes(dropzone: dropzone, date: Date.new(2026, 10, 1))
    expect(JSON.parse(entry.json.download)).to include("date" => "2026-10-01")
    expect(entry.json.filename.to_s).to eq("master-log-2026-10-01.json")
  end

  it "uses yesterday in the dropzone's time zone by default" do
    travel_to Time.utc(2026, 10, 8, 16, 30) do # 9 October 02:30 in Brisbane
      expect(described_class.run!(dropzone: dropzone).date).to eq(Date.new(2026, 10, 8))
    end
  end

  it "keeps one entry per dropzone and date" do
    described_class.run!(dropzone: dropzone, date: Date.new(2026, 10, 1))

    expect { described_class.run!(dropzone: dropzone, date: Date.new(2026, 10, 1)) }.not_to change(MasterLog, :count)
  end

  it "does not touch the entries of other dropzones" do
    other = create(:dropzone)
    described_class.run!(dropzone: other, date: Date.new(2026, 10, 1))

    expect { described_class.run!(dropzone: dropzone, date: Date.new(2026, 10, 1)) }.to change(MasterLog, :count).by(1)
  end
end
