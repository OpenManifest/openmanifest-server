# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe CreateGhost, type: :request do
    include_context('federation_sync')
    let!(:dropzone) { create(:dropzone, credits: 50) }
    let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 50) }
    before do
      dropzone_user.grant! :createUser
    end

    describe ".resolve" do
      context "successfully" do
        let(:query_str) {
          query(
            name: "rspec",
            phone: "123123123",
            email: "some@rspec.com",
            role_id: dropzone.user_roles.to_a.sample.id,
            federation_number: "321321",
            license_id: dropzone.federation.licenses.to_a.sample.id,
            exit_weight: 50,
            dropzone_id: dropzone.id
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
        it { expect { post_request }.to change(DropzoneUser, :count).by(1) }
        it { expect { post_request }.to change(User, :count).by(1) }

        it do
          post_request
          expect(json[:data][:createGhost][:user][:dropzoneUsers].first[:license]).not_to be nil
        end
      end
    end

    def query(name:, email:, phone:, exit_weight:, dropzone_id:, role_id:, license_id:, federation_number:)
      <<~GQL
        mutation {
          createGhost(
            input: {
              attributes: {
                name: "#{name}",
                email: "#{email}",
                phone: "#{phone}",
                exitWeight: #{exit_weight},
                dropzoneId: #{dropzone_id},
                roleId: #{role_id},
                licenseId: #{license_id},
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
