# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Operators, type: :request do
    describe "Owner can see public operators + operator they own" do
      let!(:moderator) { create(:user, moderation_role: :moderator) }
      let!(:fun_jumper) { create(:user, moderation_role: :user) }
      let!(:owner) { create(:user, moderation_role: :user) }
      let!(:public_operator) { create(:operator, credits: 50, state: "public") }
      let!(:private_operator) { create(:operator, credits: 50, state: "private") }
      let!(:owners_operator) { create(:operator, credits: 50, state: "private") }

      let!(:moderator_memberships) do
        [public_operator, private_operator, owners_operator].each do |operator|
          create(:membership, operator: operator, user: moderator, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
      end
      let!(:fun_jumper_memberships) do
        [public_operator, private_operator, owners_operator].each do |operator|
          create(:membership, operator: operator, user: fun_jumper, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
      end
      let!(:owner_memberships) do
        [public_operator, private_operator].each do |operator|
          create(:membership, operator: operator, user: owner, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
        create(:membership, operator: owners_operator, user: owner,
                            user_role: owners_operator.user_roles.find_by(name: :owner))
      end

      context "when querying with no variables" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let!(:query_str) { query }

        it "shows owned and public operators" do
          is_expected.to include_json(
            data: {
              operators: {
                edges: [owners_operator, public_operator].sort_by(&:id).map do |operator|
                  { node: { id: operator.id.to_s } }
                end,
              },
            }
          )
          is_expected.not_to include_json(data: { operators: { edges: [{ node: { id: private_operator.id.to_s } }] } })
        end
      end

      context "even when specifying state" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let!(:query_str) { query(state: ["private", "public", "archived"]) }

        it "shows owned and public operators" do
          is_expected.to include_json(
            data: {
              operators: {
                edges: [owners_operator.reload, public_operator.reload].sort_by(&:id).map do |operator|
                  { node: { id: operator.id.to_s } }
                end,
              },
            }
          )
          is_expected.not_to include_json(data: { operators: { edges: [{ node: { id: private_operator.id.to_s } }] } })
        end
      end
    end

    describe "Moderators can see all operators" do
      let!(:moderator) { create(:user, moderation_role: :moderator) }
      let!(:fun_jumper) { create(:user, moderation_role: :user) }
      let!(:owner) { create(:user, moderation_role: :user) }
      let!(:public_operator) { create(:operator, credits: 50, state: "public") }
      let!(:private_operator) { create(:operator, credits: 50, state: "private") }
      let!(:owners_operator) { create(:operator, credits: 50, state: "private") }

      let!(:moderator_memberships) do
        [public_operator, private_operator, owners_operator].each do |operator|
          create(:membership, operator: operator, user: moderator, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
      end
      let!(:fun_jumper_memberships) do
        [public_operator, private_operator, owners_operator].each do |operator|
          create(:membership, operator: operator, user: fun_jumper, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
      end
      let!(:owner_memberships) do
        [public_operator, private_operator].each do |operator|
          create(:membership, operator: operator, user: owner, user_role: operator.user_roles.find_by(name: :fun_jumper))
        end
        create(:membership, operator: owners_operator, user: owner,
                            user_role: owners_operator.user_roles.find_by(name: :owner))
      end

      context "when querying with no variables" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: moderator.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let!(:query_str) { query }

        it "shows all operators" do
          is_expected.to include_json(
            data: {
              operators: {
                edges: [owners_operator, public_operator, private_operator].sort_by(&:id).map do |operator|
                  { node: { id: operator.id.to_s } }
                end,
              },
            }
          )
          is_expected.not_to include_json(data: { operators: { edges: [{ node: { id: private_operator.id.to_s } }] } })
        end
      end
    end

    def query(state: nil)
      enum_states = "null"
      enum_states = "[#{state.join(',')}]" if state.present?
      <<~GQL
        query {
          operators(state: #{enum_states}) {
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
