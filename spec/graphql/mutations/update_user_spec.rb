# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe UpdateUser, type: :request do
    include_context("federation_sync")
    let!(:dropzone) { create(:dropzone, credits: 50) }
    let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 50) }
    before do
      dropzone_user.grant! :createUser
    end

    describe ".resolve" do
      context "successfully" do
        let!(:license) { dropzone.federation.licenses.where.not(id: dropzone_user&.license&.id).to_a.sample }
        let(:query_str) {
          query(
            id: dropzone_user.user.id,
            name: "rspec",
            phone: "123123123",
            email: "some@rspec.com",
            federation_number: "321321",
            license_id: license.id,
            exit_weight: 50,
          )
        }
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query_str
               },
               headers: dropzone_user.user.create_new_auth_token
        end

        let(:json) {
          JSON.parse(response.body, symbolize_names: true)
        }
        it { expect(post_request).to eq 200 }
        it do
          post_request
          expect(dropzone_user.reload.license.id).to eq license.id
        end

        it do
          post_request
          expect(json[:data][:updateUser][:user][:dropzoneUsers].first[:license]).not_to be nil
        end
      end
    end

    def query(id:, name:, email:, phone:, exit_weight:, license_id:, federation_number:)
      <<~GQL
        mutation {
          updateUser(
            input: {
              id: #{id},
              attributes: {
                name: "#{name}",
                email: "#{email}",
                phone: "#{phone}",
                exitWeight: #{exit_weight},
                licenseId: #{license_id},
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
              license {
                id
                name
              }
              dropzoneUsers {
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
