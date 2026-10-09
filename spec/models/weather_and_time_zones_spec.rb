# frozen_string_literal: true

require "rails_helper"

# P6.19: external weather calls run in a job with a timeout (BUG-045), distances keep their decimals, and "today" is the
# dropzone's day wherever the server is (BUG-046, BUG-047). The examples run the server in UTC, the dropzones in Brisbane
# (UTC+10): at 23:00 UTC it is already 09:00 of the next day there.
RSpec.describe "Weather and time zones" do
  let(:dropzone) { create(:dropzone, time_zone: "Australia/Brisbane", lat: -27.5, lng: 152.9) }
  let(:late_evening_utc) { Time.utc(2026, 10, 8, 23, 0) }
  let(:winds_url) { WeatherCondition::WINDS_URL }

  def winds_body(speed: 10, direction: 270)
    altitudes = %w(0 1000 2000 5000 7000 8000 10000 12000 14000)
    { speed: altitudes.index_with { speed }, direction: altitudes.index_with { direction }, temp: altitudes.index_with { 12 } }.to_json
  end

  around { |example| Time.use_zone("UTC") { example.run } }

  describe Dropzone, "#today" do
    it "is the date where the dropzone is" do
      travel_to(late_evening_utc) do
        expect(Time.zone.today).to eq(Date.new(2026, 10, 8))
        expect(dropzone.today).to eq(Date.new(2026, 10, 9))
      end
    end

    it "follows the dropzone's zone behind UTC too" do
      travel_to(Time.utc(2026, 10, 8, 3, 0)) do
        expect(create(:dropzone, time_zone: "America/Los_Angeles").today).to eq(Date.new(2026, 10, 7))
      end
    end

    it "falls back to Brisbane without a zone" do
      travel_to(late_evening_utc) { expect(build(:dropzone, time_zone: nil).today).to eq(Date.new(2026, 10, 9)) }
    end
  end

  describe Dropzone, "#current_conditions" do
    it "is one condition per local day" do
      travel_to(late_evening_utc) do
        first = dropzone.current_conditions

        expect(first.date).to eq(Date.new(2026, 10, 9))
        expect(dropzone.current_conditions).to eq(first)
      end
    end

    it "starts a new condition when the dropzone's day changes, not when the server's does" do
      first = travel_to(Time.utc(2026, 10, 8, 13, 59)) { dropzone.current_conditions } # 23:59 on 8 October in Brisbane
      same_local_day = travel_to(Time.utc(2026, 10, 8, 10, 0)) { dropzone.current_conditions }
      next_local_day = travel_to(Time.utc(2026, 10, 8, 14, 0)) { dropzone.current_conditions } # midnight in Brisbane

      expect(same_local_day).to eq(first)
      expect(next_local_day).not_to eq(first)
      expect(next_local_day.date).to eq(Date.new(2026, 10, 9))
    end

    it "keeps one per dropzone and day in the database" do
      condition = dropzone.current_conditions

      expect { WeatherCondition.new(dropzone: dropzone, date: condition.date).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe WeatherCondition do
    it "is created without calling the weather service" do
      expect { dropzone.current_conditions }.not_to raise_error
      expect(a_request(:get, winds_url).with(query: hash_including({}))).not_to have_been_made
    end

    it "has default winds until the job has run" do
      expect(JSON.parse(dropzone.current_conditions.winds)).to be_present
    end

    it "enqueues the winds for a dropzone with a location" do
      expect { dropzone.current_conditions }.to have_enqueued_job(FetchWindsJob)
    end

    it "does not enqueue them without a location" do
      dropzone.update!(lat: nil, lng: nil)

      expect { dropzone.current_conditions }.not_to have_enqueued_job(FetchWindsJob)
    end

    it "stores distances with decimals" do
      condition = dropzone.current_conditions
      condition.update!(exit_spot_miles: 0.55, offset_miles: 1.25)

      expect(condition.reload).to have_attributes(exit_spot_miles: BigDecimal("0.55"), offset_miles: BigDecimal("1.25"))
    end
  end

  describe FetchWindsJob do
    let!(:condition) { dropzone.current_conditions }

    it "fills the condition with the winds and the jump run" do
      stub_request(:get, winds_url).with(query: hash_including("lat" => "-27.5", "lon" => "152.9")).to_return(status: 200, body: winds_body)

      described_class.perform_now(condition.id)

      condition.reload
      expect(JSON.parse(condition.winds).first).to include("altitude" => "14000", "speed" => 10, "direction" => 270)
      expect(condition.temperature).to eq(12)
      expect(condition.jump_run).to eq(270)
      expect(condition.exit_spot_miles).to be_within(0.001).of(0.67)
    end

    it "gives the service five seconds" do
      allow(HTTParty).to receive(:get).and_call_original
      stub_request(:get, winds_url).with(query: hash_including({})).to_return(status: 200, body: winds_body)

      described_class.perform_now(condition.id)

      expect(HTTParty).to have_received(:get).with(winds_url, hash_including(timeout: 5))
    end

    it "is retried when the service does not answer" do
      stub_request(:get, winds_url).with(query: hash_including({})).to_timeout

      expect { described_class.perform_now(condition.id) }.to have_enqueued_job(described_class).with(condition.id)
    end

    it "keeps the default winds when the answer cannot be used" do
      stub_request(:get, winds_url).with(query: hash_including({})).to_return(status: 200, body: "not json")

      expect { described_class.perform_now(condition.id) }.to raise_error(JSON::ParserError)
      expect(JSON.parse(condition.reload.winds)).to be_present
    end

    it "is discarded when the condition is gone" do
      id = condition.id
      condition.destroy

      expect { described_class.perform_now(id) }.not_to raise_error
    end
  end

  describe "loads of the dropzone's day" do
    let(:plane) { create(:plane, dropzone: dropzone) }

    def create_load_at(time, **attrs)
      travel_to(time) { create(:load, plane: plane, **attrs) }
    end

    it "numbers and dates a load by the dropzone's day" do
      evening = create_load_at(Time.utc(2026, 10, 8, 16, 0))   # 02:00 on 9 October in Brisbane
      night = create_load_at(Time.utc(2026, 10, 8, 23, 0))     # 09:00 on 9 October in Brisbane

      expect([evening.load_date, night.load_date].uniq).to eq([Date.new(2026, 10, 9)])
      expect([evening.load_number, night.load_number]).to eq([1, 2])
    end

    it "finds today's loads by the dropzone's day" do
      create_load_at(Time.utc(2026, 10, 8, 9, 0))              # yesterday afternoon in Brisbane
      today = create_load_at(Time.utc(2026, 10, 8, 16, 0))

      travel_to(late_evening_utc) do
        expect(Load.today_at(dropzone)).to contain_exactly(today)
        expect(dropzone.loads.on(dropzone.today)).to contain_exactly(today)
      end
    end

    it "refuses double manifesting on a load of the dropzone's day while the server is on the day before" do
      member = create(:dropzone_user, dropzone: dropzone, credits: 500)
      first = create_load_at(Time.utc(2026, 10, 8, 16, 0))
      second = create_load_at(Time.utc(2026, 10, 8, 17, 0))
      ticket = create(:ticket_type, dropzone: dropzone, cost: 10)
      jump_type = JumpType.allowed_for([member]).first
      create(:slot, load: first, dropzone: dropzone, dropzone_user: member, ticket_type: ticket, jump_type: jump_type)

      travel_to(late_evening_utc) do
        slot = Slot.new(load: second, dropzone_user: member, ticket_type: ticket, jump_type: jump_type, exit_weight: 80, created_by: member)

        expect(slot).not_to be_valid
        expect(slot.errors.full_messages).to include("Double-manifesting is not allowed")
      end
    end

    it "finalizes the loads of earlier local days only" do
      yesterday = create_load_at(Time.utc(2026, 10, 8, 9, 0), dispatch_at: Time.utc(2026, 10, 8, 9, 30))
      today = create_load_at(Time.utc(2026, 10, 8, 16, 0))

      travel_to(late_evening_utc) { Manifest::Schedule::AutoFinalize.run! }

      expect(yesterday.reload.state).to eq("landed")
      expect(today.reload.state).to eq("open")
    end
  end
end
