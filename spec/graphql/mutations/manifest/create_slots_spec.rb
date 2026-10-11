# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Manifest::CreateSlots, type: :request do
    let(:operator) { create(:operator, credits: 50) }
    let(:plane) { create(:plane, operator: operator, max_slots: 10) }
    let(:ticket_type) { create(:ticket_type, operator: operator) }
    let(:gca) { create(:membership, operator: operator) }
    let(:pilot) { create(:membership, operator: operator) }
    let(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
    let(:memberships) { create_list(:membership, 3, operator: operator, credits: 200) }
    let(:membership) do
      u = memberships.first
      u.grant! :createUserSlot
      u
    end

    describe ".resolve" do
      context "successfully" do
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   jump_type: JumpType.allowed_for(memberships).sample,
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   user_group: memberships.map { |user| { id: user.id, exit_weight: user.user.exit_weight } }
                 ),
               },
               headers: membership.user.create_new_auth_token
          JSON.parse(response.body)
        end

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by memberships.count }

        it "expects credits to update" do
          post_request
          memberships.each do |user|
            expect(user.reload.credits).to eq 200 - ticket_type.cost
          end
        end
        it "expects orders to update" do
          post_request
          memberships.each do |user|
            expect(user.reload.purchases.count).to eq 1
          end
        end
        it { expect { post_request }.to change { ::Operator.find(operator.id).credits }.by ticket_type.cost * memberships.count }
        it { expect { post_request }.to change { ::Operator.find(operator.id).sales.count }.by memberships.count }
        it { expect(post_request["data"]["createSlots"]["errors"]).to be nil }
      end

      context "successfully with tandem" do
        let!(:ticket_type) { create(:ticket_type, is_tandem: true, operator: operator) }
        let(:post_request) do
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   jump_type: JumpType.allowed_for(memberships).sample,
                   user_group: memberships.map do |user|
                     {
                       id: user.id, exit_weight: user.user.exit_weight, passenger_name: Faker::Name.first_name,
                       passenger_exit_weight: 80,
                     }
                   end
                 ),
               },
               headers: membership.user.create_new_auth_token
          JSON.parse(response.body)
        end

        it { expect { post_request }.to change { Slot.where(load_id: plane_load.id).count }.by memberships.count * 2 }
        it do
          expect { post_request }.to change { ::Slot.where(load_id: plane_load.id, membership: membership).count }.by 1
          expect { post_request }.not_to change { ::Membership.find(membership.id).credits }
          expect { post_request }.not_to change { ::Operator.find(operator.id).credits }
        end
        it { expect { post_request }.to change { Order.where(seller: operator).count }.by memberships.count }
        it { expect(post_request["data"]["createSlots"]["errors"]).to be nil }
        it { expect(post_request["data"]["createSlots"]["fieldErrors"]).to be nil }
      end

      context "with errors" do
        before do
          memberships.sample.update(credits: 0)
          post "/graphql",
               params: {
                 query: query(
                   ticket_type: ticket_type,
                   plane_load: plane_load,
                   jump_type: JumpType.allowed_for(memberships).sample,
                   user_group: memberships.map { |user| { id: user.id, exit_weight: user.user.exit_weight } }
                 ),
               },
               headers: membership.user.create_new_auth_token
        end

        let(:json) do
          JSON.parse(response.body)
        end

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
                ticketType: #{ticket_type.id}
                jumpType: #{jump_type.id}
                load: #{plane_load.id}
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
                membership {
                  id
                  user {
                    id
                    name
                  }
                }
                costCents
                order {
                  id
                  buyer {
                    ...on Membership {
                      id
                      user {
                        id
                        name
                      }
                    }
                    ...on Operator {
                      id
                      name
                    }
                  }
                  seller {
                    ...on Membership {
                      id
                      user {
                        id
                        name
                      }
                    }
                    ...on Operator {
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
                        ...on Membership {
                          id
                          user {
                            id
                            name
                          }
                        }
                        ...on Operator {
                          id
                          name
                        }
                      }
                      receiver {
                        ...on Membership {
                          id
                          user {
                            id
                            name
                          }
                        }
                        ...on Operator {
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
