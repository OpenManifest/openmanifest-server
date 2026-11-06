# frozen_string_literal: true

require "rails_helper"

# BUG-052: jobs run on Solid Queue with retries and nothing is swallowed. BUG-044: master logs and auto-finalize are scheduled.
RSpec.describe "Background jobs" do
  describe "configuration" do
    it "runs on Solid Queue outside the test environment" do
      expect(Rails.application.config.active_job.queue_adapter).to eq(:test)
      expect(Dz::Application.config.active_job.queue_adapter).to eq(:test)
      expect(Rails.root.join("config/application.rb").read).to include("config.active_job.queue_adapter = :solid_queue")
    end

    %w(development production).each do |environment|
      describe "config/recurring.yml (#{environment})" do
        let(:tasks) { Rails.application.config_for(:recurring, env: environment) }

        it "schedules auto-finalize every 15 minutes and the master logs hourly" do
          expect(tasks).to include(auto_finalize: include(class: "AutoFinalizeJob", schedule: "every 15 minutes"),
                                   daily_logs: include(class: "DailyLogsJob", schedule: "every hour at minute 5"))
        end

        it "has tasks Solid Queue accepts" do
          tasks.each do |key, options|
            task = SolidQueue::RecurringTask.from_configuration(key.to_s, **options)

            expect(task).to be_valid, "#{key}: #{task.errors.full_messages.join(', ')}"
            expect(task.next_time).to be_a(Time) if options[:class]
          end
        end
      end
    end
  end

  describe NotifyJob do
    let(:operator) { create(:operator) }
    let(:member) { create(:membership, operator: operator) }
    let!(:notification) do
      member.user.update!(push_token: "ExponentPushToken[abc]")
      Notification.create!(received_by: member, message: "Load #1 take off at 10:00", resource: operator, notification_type: :system)
    end

    it "is enqueued when a notification is created" do
      expect { Notification.create!(received_by: member, message: "Hi", resource: operator, notification_type: :system) }.to have_enqueued_job(described_class)
    end

    it "sends the push notification" do
      stub = stub_request(:post, "https://exp.host/--/api/v2/push/send").to_return(status: 200, body: "{}")

      described_class.perform_now(notification.id)

      expect(stub).to have_been_requested
    end

    [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, HTTParty::Error].each do |error|
      it "is retried later after #{error}" do
        stub_request(:post, "https://exp.host/--/api/v2/push/send").to_raise(error)

        expect { described_class.perform_now(notification.id) }.to have_enqueued_job(described_class).with(notification.id)
      end
    end

    it "gives up after five attempts and raises the error" do
      stub_request(:post, "https://exp.host/--/api/v2/push/send").to_raise(Net::OpenTimeout)
      job = described_class.new(notification.id)

      4.times { job.perform_now }
      expect { job.perform_now }.to raise_error(Net::OpenTimeout)
    end

    it "is discarded when the notification is gone" do
      id = notification.id
      notification.destroy

      expect { described_class.perform_now(id) }.not_to have_enqueued_job(described_class)
    end

    it "does not hide other errors" do
      allow_any_instance_of(Notification).to receive(:deliver).and_raise(ArgumentError, "bug")

      expect { described_class.perform_now(notification.id) }.to raise_error(ArgumentError, "bug")
    end
  end

  describe AutoFinalizeJob do
    it "lands the called loads of past days and cancels the rest" do
      operator = create(:operator)
      vehicle = create(:vehicle, operator: operator)
      called = create(:load, vehicle: vehicle, created_at: 2.days.ago, dispatch_at: 2.days.ago)
      never_called = create(:load, vehicle: vehicle, created_at: 2.days.ago)
      today = create(:load, vehicle: vehicle)

      described_class.perform_now

      expect([called, never_called, today].map { |load| load.reload.state }).to eq(%w(completed cancelled open))
    end
  end

  describe DailyLogsJob do
    let(:brisbane) { create(:operator, time_zone: "Australia/Brisbane") }
    let(:los_angeles) { create(:operator, time_zone: "America/Los_Angeles") }
    # 16:30 UTC is 02:30 on 9 October in Brisbane (UTC+10) and 09:30 on 9 October in Los Angeles (UTC-7)
    let(:now) { Time.utc(2026, 10, 8, 16, 30) }

    before { [brisbane, los_angeles] }

    it "generates yesterday's log for the operators that are in their 02:00 hour" do
      described_class.perform_now(now)

      expect(brisbane.daily_logs.pluck(:date)).to eq([Date.new(2026, 10, 8)])
      expect(los_angeles.daily_logs).to be_empty
    end

    it "stores the log with its loads" do
      vehicle = create(:vehicle, operator: brisbane)
      load = create(:load, vehicle: vehicle, dispatch_at: Time.utc(2026, 10, 8, 3, 0))
      create(:load, vehicle: vehicle, dispatch_at: Time.utc(2026, 10, 7, 3, 0))

      described_class.perform_now(now)

      json = JSON.parse(brisbane.daily_logs.last.json.download)
      expect(json).to include("date" => "2026-10-08")
      expect(json["loads"].pluck("id")).to eq([load.id])
    end

    it "refreshes the log when it exists" do
      log = brisbane.daily_logs.create!(date: Date.new(2026, 10, 8))
      vehicle = create(:vehicle, operator: brisbane)
      create(:load, vehicle: vehicle, dispatch_at: Time.utc(2026, 10, 8, 3, 0))

      expect { described_class.perform_now(now) }.not_to change(DailyLog, :count)
      expect(JSON.parse(log.reload.json.download)["loads"].size).to eq(1)
    end

    it "catches up when an operator is past 02:59, flew yesterday and has no log" do
      create(:load, vehicle: create(:vehicle, operator: brisbane), dispatch_at: Time.utc(2026, 10, 8, 3, 0))

      described_class.perform_now(Time.utc(2026, 10, 8, 18, 0)) # 04:00 in Brisbane

      expect(brisbane.daily_logs.pluck(:date)).to eq([Date.new(2026, 10, 8)])
    end

    it "does not catch up for an operator that did not fly" do
      described_class.perform_now(Time.utc(2026, 10, 8, 18, 0))

      expect(DailyLog.count).to eq(0)
    end

    it "does not generate before 02:00" do
      described_class.perform_now(Time.utc(2026, 10, 8, 15, 30)) # 01:30 in Brisbane

      expect(DailyLog.count).to eq(0)
    end
  end
end
