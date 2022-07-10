# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Manifest::CreateSlots, type: :request do
    let!(:dropzone) { create(:dropzone, credits: 50) }
    let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
    let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
    let!(:plane_load) { create(:load, plane: plane) }
    let!(:dropzone_users) { create_list(:dropzone_user, 3, dropzone: dropzone, credits: 200) }
    let!(:jump_type) { JumpType.allowed_for(dropzone_users).sample }
    let!(:dropzone_user) do
      u = dropzone_users.first
      u.grant! :createUserSlot
      u
    end
    describe ".resolve" do
      context "successfully" do
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   jump_type: jump_type,
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   user_group: dropzone_users.map { |user| { id: user.id, exit_weight: user.user.exit_weight } }
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
          JSON.parse(response.body)
        end

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by dropzone_users.count }

        it "expects credits to update" do
          post_request
          dropzone_users.each do |user|
            expect(user.reload.credits).to eq 200 - ticket_type.cost
          end
        end
        it "expects orders to update" do
          post_request
          dropzone_users.each do |user|
            expect(user.reload.purchases.count).to eq 1
          end
        end
        it { expect { post_request }.to change { Dropzone.find(dropzone.id).credits }.by ticket_type.cost * dropzone_users.count }
        it { expect { post_request }.to change { Dropzone.find(dropzone.id).sales.count }.by dropzone_users.count }
        it { expect(post_request["data"]["createSlots"]["errors"]).to be nil }
      end

      context "successfully with tandem" do
        let!(:ticket_type) { create(:ticket_type, is_tandem: true, dropzone: dropzone) }
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   jump_type: jump_type,
                   user_group: dropzone_users.map do |user|
                     { id: user.id, exit_weight: user.user.exit_weight, passenger_name: Faker::Name.first_name, passenger_exit_weight: 80 }
                   end
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
          JSON.parse(response.body)
        end

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by dropzone_users.count * 2 }
        it do
          expect { post_request }.to change { Slot.where(load_id: plane_load.id, dropzone_user: dropzone_user).count }.by 1
          expect { post_request }.not_to change { DropzoneUser.find(dropzone_user.id).credits }
          expect { post_request }.not_to change { Dropzone.find(dropzone.id).credits }
        end
        it { expect { post_request }.to change { Order.where(seller: dropzone).count }.by dropzone_users.count }
        it { expect(post_request["data"]["createSlots"]["errors"]).to be nil }
        it { expect(post_request["data"]["createSlots"]["fieldErrors"]).to be nil }
      end

      context "with errors" do
        before do
          dropzone_users.sample.update(credits: 0)
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   jump_type: jump_type,
                   user_group: dropzone_users.map { |user| { id: user.id, exit_weight: user.user.exit_weight } }
                 )
               },
               headers: dropzone_user.user.create_new_auth_token
        end

        let(:json) {
          JSON.parse(response.body)
        }

        it { expect(json["data"]["createSlots"]["errors"]).not_to be_empty }
        it { expect(json["data"]["createSlots"]["fieldErrors"].count).to eq 1 }
        it { expect(json["data"]["createSlots"]["fieldErrors"][0]["field"]).to eq "credits" }
      end
    end

    def query(user_group:, ticket_type:, plane_load:, jump_type:)
      <<~GQL
        mutation {
          createSlots(
            input: {
              attributes: {
                ticketTypeId: #{ticket_type.id}
                jumpTypeId: #{jump_type.id}
                loadId: #{plane_load.id}
                userGroup: [
                  #{user_group.map do |u|
                    "{
                      id: #{u[:id]},
                      exitWeight: #{u[:exit_weight]},
                      passengerName: #{u[:passenger_name] ? '"%s"' % u[:passenger_name] : 'null'},
                      passengerExitWeight: #{u[:passenger_exit_weight] || 'null'}
                    },"
                  end.join("\n")}
                ]
              }
            }
          ) {
            errors
            fieldErrors {
              field
              message
            }
            load {
              id
              slots {
                id
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
        }
      GQL
    end
  end
end
