# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::Manifest::CreateSlot, type: :request do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:vehicle) { create(:vehicle, operator: operator, capacity: 10) }
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:gca) { create(:membership, operator: operator) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:vehicle_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: gca) }
  let!(:membership) { create(:membership, operator: operator, credits: 200) }

  describe ".resolve" do
    context "successfully" do
      let(:post_request) do
        post "/graphql",
             params: {
               query: query(
                 ticket_type: ticket_type,
                 vehicle_load: vehicle_load,
                 membership: membership,
                 body_mass_kg: membership.body_mass_kg || 105
               ),
             },
             headers: membership.user.create_new_auth_token
      end

      let(:json) do
        JSON.parse(response.body)
      end

      it { expect { post_request }.to change { Slot.where(load_id: vehicle_load.id).count }.by 1 }
      it { expect { post_request }.to change { Membership.find(membership.id).credits }.by ticket_type.cost * -1 }
      it { expect { post_request }.to change { Operator.find(operator.id).credits }.by ticket_type.cost }
      it { expect { post_request }.to change { Operator.find(operator.id).sales.count }.by 1 }
      it { expect { post_request }.to change { Membership.find(membership.id).purchases.count }.by 1 }
      it "expects no errors" do
        post_request
        expect(json["data"]["createSlot"]["errors"]).to be nil
      end
      it "expects no errors" do
        post_request
        expect(json["data"]["createSlot"]["slot"]["bodyMassKg"]).to eq membership.body_mass_kg
      end
    end

    context "successfully with tandem" do
      let!(:ticket_type) { create(:ticket_type, requires_escort: true, operator: operator) }
      let(:post_request) do
        post "/graphql",
             params: {
               query: query(
                 ticket_type: ticket_type,
                 vehicle_load: vehicle_load,
                 membership: membership,
                 body_mass_kg: membership.user.body_mass_kg,
                 guests: '[{ name: "Eric", bodyMassKg: 60.0 }]'
               ),
             },
             headers: membership.user.create_new_auth_token
        JSON.parse(response.body)
      end

      it { expect { post_request }.to change { Slot.where(load_id: vehicle_load.id).count }.by 2 }
      it { expect { post_request }.to change { Slot.where(load_id: vehicle_load.id, membership: membership).count }.by 1 }
      it { expect { post_request }.not_to change { Membership.find(membership.id).credits } }
      it { expect { post_request }.not_to change { Operator.find(operator.id).credits } }
      it { expect { post_request }.not_to change { Order.where(seller: operator).count } }
      it { expect(post_request["data"]["createSlot"]["errors"]).to be nil }
      it { expect(post_request["data"]["createSlot"]["fieldErrors"]).to be nil }
      it { expect { post_request }.to change { Activity::Event.count } }
    end

    context "with errors" do
      before do
        membership.update(credits: 0)
        post "/graphql",
             params: {
               query: query(
                 ticket_type: ticket_type,
                 vehicle_load: vehicle_load,
                 membership: membership,
                 body_mass_kg: membership.user.body_mass_kg
               ),
             },
             headers: membership.user.create_new_auth_token
      end

      let(:json) do
        JSON.parse(response.body)
      end

      it { expect(json["data"]["createSlot"]["errors"]).not_to be_empty }
      it { expect(json["data"]["createSlot"]["fieldErrors"]).to be_empty }
      it { expect(json["data"]["createSlot"]["errors"].first).to match(/credits/) }
    end
  end

  def query(membership:, ticket_type:, vehicle_load:, body_mass_kg:, guests: nil)
    <<~GQL
      mutation {
        createSlot(
          input: {
            attributes: {
              membership: "#{membership.id}"
              ticketType: "#{ticket_type.id}"
              activityType: #{ActivityType.allowed_for([membership]).sample.id}
              load: "#{vehicle_load.id}"
              bodyMassKg: #{body_mass_kg}
              guests: #{guests || 'null'}
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
            bodyMassKg
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
    GQL
  end
end
