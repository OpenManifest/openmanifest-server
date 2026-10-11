# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resolvers::Operator::Loads, type: :request do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:membership) { create(:membership, operator: operator) }
  let!(:plane) { create(:plane, operator: operator) }
  let!(:gca) { create(:membership, operator: operator) }
  let!(:pilot) { create(:membership, operator: operator) }
  # The resolver reads the date in the operator's time zone, so the spec must too (UTC is a day behind for part of the day)
  let(:today) { Time.use_zone(operator.time_zone) { Date.current } }
  let!(:load1) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.ago) }
  let!(:load2) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: Time.use_zone(operator.time_zone) { Time.zone.local(today.year, today.month, today.day) + 5.hours }) }
  let!(:load3) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.from_now) }

  describe ".resolve" do
    context "successfully" do
      subject do
        post "/graphql",
             params: { query: query_str },
             headers: membership.user.create_new_auth_token
        x = JSON.parse(response.body, symbolize_names: true)
        puts x
        x
      end

      let(:query_str) do
        query(
          operator: operator.id,
          date: today.iso8601
        )
      end

      it { is_expected.to include_json(data: { loads: { edges: [{ node: { id: load2.id.to_s } }] } }) }
      it { is_expected.not_to include_json(data: { loads: { edges: [{ node: { id: load1.id.to_s } }] } }) }
      it { is_expected.not_to include_json(data: { loads: { edges: [{ node: { id: load3.id.to_s } }] } }) }
    end
  end

  def query(operator:, date:)
    <<~GQL
      query {
        loads(
          operator: "#{operator}",
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
