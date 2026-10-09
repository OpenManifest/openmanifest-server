# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resolvers::Dropzone::Loads, type: :request do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone) }
  let!(:plane) { create(:plane, dropzone: dropzone) }
  let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  # The resolver reads the date in the dropzone's time zone, so the spec must too (UTC is a day behind for part of the day)
  let(:today) { Time.use_zone(dropzone.time_zone) { Date.current } }
  let!(:load1) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.ago) }
  let!(:load2) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: Time.use_zone(dropzone.time_zone) { Time.zone.local(today.year, today.month, today.day) + 5.hours }) }
  let!(:load3) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.from_now) }

  describe ".resolve" do
    context "successfully" do
      subject do
        post "/graphql",
             params: { query: query_str },
             headers: dropzone_user.user.create_new_auth_token
        x = JSON.parse(response.body, symbolize_names: true)
        puts x
        x
      end

      let(:query_str) do
        query(
          dropzone: dropzone.id,
          date: today.iso8601
        )
      end

      it { is_expected.to include_json(data: { loads: { edges: [{ node: { id: load2.id.to_s } }] } }) }
      it { is_expected.not_to include_json(data: { loads: { edges: [{ node: { id: load1.id.to_s } }] } }) }
      it { is_expected.not_to include_json(data: { loads: { edges: [{ node: { id: load3.id.to_s } }] } }) }
    end
  end

  def query(dropzone:, date:)
    <<~GQL
      query {
        loads(
          dropzone: "#{dropzone}",
          date: "#{date}"
        ) {
          edges {
            node {
              id
            }
          }
        }
      }
    GQL
  end
end
