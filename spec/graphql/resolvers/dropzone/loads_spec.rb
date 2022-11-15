# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Dropzone::Loads, type: :request do
    let!(:dropzone) { create(:dropzone, credits: 50) }
    let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone) }
    let!(:plane) { create(:plane, dropzone: dropzone) }
    let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
    let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
    let!(:load1) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.ago) }
    let!(:load2) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: DateTime.current.beginning_of_day + 5.hours) }
    let!(:load3) { create(:load, plane: plane, pilot: pilot, gca: gca, created_at: 1.day.from_now) }

    describe ".resolve" do
      context "successfully" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: dropzone_user.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            dropzone: dropzone.id,
            date: Date.today.iso8601
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
end
