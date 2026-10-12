# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resolvers::Operator::DailyLog, type: :request do
  include_context 'operator_with_manifested_loads'

  # The log's day is the operator's, not UTC's
  let(:today) { Time.use_zone(operator.time_zone) { Date.current } }

  before do
    # P6.2: reading the master log needs updateOperator, the permission that writes it (the caller used to be any member)
    fun_jumper.grant!(:updateOperator)
    load.update(dispatch_at: 10.minutes.from_now)
    load.complete

    load2.cancel
  end

  describe ".resolve" do
    context "successfully" do
      subject { execute_query(operator: operator.id, date: today.iso8601) }

      it 'includes finalized loads' do
        is_expected.to include_json(
          dailyLog: {
            date: today.iso8601,
            downloadUrl: /\w+/,
            loads: [
              {
                id: load.id.to_s,
                dispatchAt: load.dispatch_at.iso8601,
                pilot: { name: load.pilot.name },
                slots: load.slots.map do |slot|
                         { id: slot.id.to_s, name: slot.membership.name, activityType: slot.activity_type.name, altitude: slot.destination.altitude_ft }
                       end,
              },
            ],
          }
        )
      end

      it 'refuses a member without updateOperator' do
        fun_jumper.revoke!(:updateOperator)

        expect(execute_query(operator: operator.id, date: today.iso8601)&.dig(:dailyLog)).to be_nil
      end

      it 'does not include cancelled loads' do
        is_expected.to have_attributes(size: 1)
        is_expected.not_to include_json(
          dailyLog: {
            loads: [
              { id: load2.id.to_s },
            ],
          }
        )
      end
    end
  end

  create_query(:operator, :date) do
    <<~GQL
      query {
        dailyLog(operator: "#{operator}", date: "#{date}") {
          date
          dutyOfficer {
            name
          }
          downloadUrl
          loads {
            id
            dispatchAt
            pilot {
              name
            }
            slots {
              id
              name
              activityType
              altitude
            }
          }
        }
      }
    GQL
  end
end
