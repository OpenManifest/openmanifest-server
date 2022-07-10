# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Manifest::CreateSlot, type: :request do
    let!(:dropzone) { create(:dropzone, credits: 50) }
    let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
    let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
    let!(:plane_load) { create(:load, plane: plane) }
    let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }

    describe ".resolve" do
      context "successfully" do
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   dropzone_user: dropzone_user,
                   exit_weight: dropzone_user.exit_weight || 105
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
        end

        let(:json) {
          JSON.parse(response.body)
        }

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by 1 }
        it { expect { post_request }.to change { DropzoneUser.find(dropzone_user.id).credits }.by ticket_type.cost * -1 }
        it { expect { post_request }.to change { Dropzone.find(dropzone.id).credits }.by ticket_type.cost }
        it { expect { post_request }.to change { Dropzone.find(dropzone.id).sales.count }.by 1 }
        it { expect { post_request }.to change { DropzoneUser.find(dropzone_user.id).purchases.count }.by 1 }
        it "expects no errors" do
          post_request
          expect(json["data"]["createSlot"]["errors"]).to be nil
        end
        it "expects no errors" do
          post_request
          expect(json["data"]["createSlot"]["slot"]["exitWeight"]).to eq dropzone_user.exit_weight
        end
      end

      context "successfully with tandem" do
        let!(:ticket_type) { create(:ticket_type, is_tandem: true, dropzone: dropzone) }
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   dropzone_user: dropzone_user,
                   exit_weight: dropzone_user.user.exit_weight,
                   passenger_name: '"Eric"',
                   passenger_exit_weight: 60.0
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
          JSON.parse(response.body)
        end

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by 2 }
        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id, dropzone_user: dropzone_user).count }.by 1 }
        it { expect { post_request }.not_to change { DropzoneUser.find(dropzone_user.id).credits } }
        it { expect { post_request }.not_to change { Dropzone.find(dropzone.id).credits } }
        it { expect { post_request }.to change { Order.where(seller: dropzone).count }.by 1 }
        it { expect(post_request["data"]["createSlot"]["errors"]).to be nil }
        it { expect(post_request["data"]["createSlot"]["fieldErrors"]).to be nil }
      end

      context "with errors" do
        before do
          dropzone_user.update(credits: 0)
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   dropzone_user: dropzone_user,
                   exit_weight: dropzone_user.user.exit_weight
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
        end

        let(:json) {
          JSON.parse(response.body)
        }

        it { expect(json["data"]["createSlot"]["errors"]).not_to be_empty }
        it { expect(json["data"]["createSlot"]["fieldErrors"]).to be_empty }
        it { expect(json["data"]["createSlot"]["errors"].first).to match(/credits/) }
      end
    end

    def query(dropzone_user:, ticket_type:, plane_load:, exit_weight:, passenger_name: nil, passenger_exit_weight: nil)
      <<~GQL
        mutation {
          createSlot(
            input: {
              attributes: {
                dropzoneUserId: #{dropzone_user.id}
                ticketTypeId: #{ticket_type.id}
                jumpTypeId: #{JumpType.allowed_for([dropzone_user]).sample.id}
                loadId: #{plane_load.id}
                exitWeight: #{exit_weight}
                passengerExitWeight: #{passenger_exit_weight || 'null'}
                passengerName: #{passenger_name || 'null'}
              }
            }
          ) {
            errors
            fieldErrors {
              field
              message
            }
            slot {
              id
              exitWeight
              dropzoneUser {
                id
                user {
                  id
                  name
                }
              }
              cost
              order {
                id
                buyer {
                  ...on DropzoneUser {
                    id
                    user {
                      id
                      name
                    }
                  }
                  ...on Dropzone {
                    id
                    name
                  }
                }
                seller {
                  ...on DropzoneUser {
                    id
                    user {
                      id
                      name
                    }
                  }
                  ...on Dropzone {
                    id
                    name
                  }
                }
                receipts {
                  id
                  transactions {
                    id
                    transactionType
                    status
                    sender {
                      ...on DropzoneUser {
                        id
                        user {
                          id
                          name
                        }
                      }
                      ...on Dropzone {
                        id
                        name
                      }
                    }
                    receiver {
                      ...on DropzoneUser {
                        id
                        user {
                          id
                          name
                        }
                      }
                      ...on Dropzone {
                        id
                        name
                      }
                    }
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
