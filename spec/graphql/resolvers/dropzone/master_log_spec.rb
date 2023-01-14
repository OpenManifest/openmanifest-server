# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resolvers::Dropzone::MasterLog, type: :request do
  include_context 'dropzone_with_manifested_loads'

  before do
    load.update(dispatch_at: 10.minutes.from_now)
    load.mark_as_landed

    load2.cancel
  end

  describe ".resolve" do
    context "successfully" do
      subject { execute_query(dropzone: dropzone.id, date: Date.today.iso8601) }

      it 'includes finalized loads' do
        is_expected.to include_json(
          masterLog: {
            date: Date.today.iso8601,
            loads: [
              {
                id: load.id.to_s,
                dispatchAt: load.dispatch_at.iso8601,
                slots: load.slots.map do |slot|
                         { id: slot.id.to_s, name: slot.dropzone_user.name, jumpType: slot.jump_type.name, altitude: slot.ticket_type.altitude }
                       end,
              },
            ],
          }
        )
      end

      it 'does not include cancelled loads' do
        is_expected.to have_attributes(size: 1)
        is_expected.not_to include_json(
          masterLog: {
            loads: [
              { id: load2.id.to_s },
            ],
          }
        )
      end
    end
  end

  create_query(:dropzone, :date) do
    <<~GQL
      query {
        masterLog(dropzone: "#{dropzone}", date: "#{date}") {
          date
          loads {
            id
            dispatchAt
            slots {
              id
              name
              jumpType
              altitude
            }
          }
        }
      }
    GQL
  end
end
