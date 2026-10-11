# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Users::UpdateUser, type: :request do
    include_context("federation_sync")
    let!(:operator) { create(:operator, credits: 50) }
    let!(:membership) { create(:membership, operator: operator, credits: 50) }

    let!(:apf_response) do
      []
    end

    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
        to_return(body: apf_response.to_json, headers: { "Content-Type" => "application/json" })
      membership.grant! :createUser
    end

    describe ".resolve" do
      context "successfully" do
        let!(:license) { operator.federation.licenses.where.not(id: membership&.license&.id).to_a.sample }
        let(:query_str) do
          query(
            id: membership.user.id,
            name: "rspec",
            phone: "123123123",
            email: "some@rspec.com",
            federation_number: "321321",
            license_id: license.reload.id,
            exit_weight: 50,
          )
        end
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query_str,
               },
               headers: membership.user.create_new_auth_token
        end

        let(:json) do
          JSON.parse(response.body, symbolize_names: true)
        end

        it { expect(post_request).to eq 200 }
        it do
          post_request
          expect(membership.reload.license.id).to eq license.reload.id
          expect(json[:data][:updateUser][:membership][:user][:memberships].find do |d|
                   d[:id].to_i == membership.id
                 end[:license][:id].to_i).to eq license.reload.id
        end
      end
    end

    def query(id:, name:, email:, phone:, exit_weight:, license_id:, federation_number:)
      <<~GQL
        mutation {
          updateUser(
            input: {
              membership: #{membership.id},
              attributes: {
                name: "#{name}",
                email: "#{email}",
                phone: "#{phone}",
                exitWeight: #{exit_weight},
                license: #{license_id},
              }
            }
          ) {
            errors
            fieldErrors {
              field
              message
            }
            membership {
              id
              user {
                id
                name
                phone
                memberships {
                  id
                  license {
                    id
                    name
                  }
                }
              }
            }
          }
        }
      GQL
    end
  end
end
