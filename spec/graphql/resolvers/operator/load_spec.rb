# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Operator::Load, type: :request do
    let!(:operator) { create(:operator, credits: 50) }
    let!(:membership) { create(:membership, operator: operator) }
    let!(:vehicle) { create(:vehicle, operator: operator) }
    let!(:gca) { create(:membership, operator: operator) }
    let!(:pilot) { create(:membership, operator: operator) }
    let!(:load1) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot, created_at: 1.day.ago) }
    let!(:load2) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot, created_at: DateTime.current.beginning_of_day + 5.hours) }
    let!(:load3) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot, created_at: 1.day.from_now) }

    before do
      membership.grant! :createUser
    end

    describe ".resolve" do
      context "successfully" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: membership.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: load2.id
          )
        end

        it { is_expected.to include_json(data: { load: { id: load2.id.to_s } }) }
        it { is_expected.not_to include_json(data: { load: { id: load1.id.to_s } }) }
        it { is_expected.not_to include_json(data: { load: { id: load3.id.to_s } }) }
      end
    end

    def query(id:)
      <<~GQL
        query {
          load(
            id: "#{id}",
          ) {
            id
          }
        }
      GQL
    end
  end
end
