# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Users::CreateGhost, type: :request do
    include_context("federation_sync")
    let!(:operator) { create(:operator, credits: 50) }
    let!(:membership) { create(:membership, operator: operator, credits: 50) }

    before do
      membership.grant! :createUser
    end

    describe ".resolve" do
      context "successfully" do
        let(:query_str) do
          query(
            name: "rspec",
            phone: "123123123",
            email: "some@rspec.com",
            role_id: operator.user_roles.to_a.sample.id,
            federation_number: "321321",
            license_id: operator.federation.licenses.to_a.sample.id,
            body_mass_kg: 50,
            operator_id: operator.id
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
        it { expect { post_request }.to change(Membership, :count).by(1) }
        it { expect { post_request }.to change(User, :count).by(1) }

        it do
          post_request
          expect(json[:data][:createGhost][:user][:memberships].first[:license]).not_to be nil
        end
      end
    end

    def query(name:, email:, phone:, body_mass_kg:, operator_id:, role_id:, license_id:, federation_number:)
      <<~GQL
        mutation {
          createGhost(
            input: {
              attributes: {
                name: "#{name}",
                email: "#{email}",
                phone: "#{phone}",
                bodyMassKg: #{body_mass_kg},
                operator: #{operator_id},
                role: #{role_id},
                license: #{license_id},
                federationNumber: "#{federation_number}"
              }
            }
          ) {
            errors
            fieldErrors {
              field
              message
            }
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
      GQL
    end
  end
end
