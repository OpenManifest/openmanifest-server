# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Dropzones, type: :request do
    let!(:moderator) { create(:user, moderation_role: :moderator) }
    let!(:fun_jumper) { create(:user, moderation_role: :user) }
    let!(:owner) { create(:user, moderation_role: :user) }
    let!(:public_dropzone) { create(:dropzone, credits: 50, state: 'public') }
    let!(:private_dropzone) { create(:dropzone, credits: 50, state: 'private') }
    let!(:owners_dropzone) { create(:dropzone, credits: 50, state: 'private') }

    let!(:moderator_dropzone_users) do
      [public_dropzone, private_dropzone, owners_dropzone].each do |dropzone|
        create(:dropzone_user, dropzone: dropzone, user: moderator, user_role: dropzone.user_roles.find_by(name: :fun_jumper))
      end
    end
    let!(:fun_jumper_dropzone_users) do
      [public_dropzone, private_dropzone, owners_dropzone].each do |dropzone|
        create(:dropzone_user, dropzone: dropzone, user: fun_jumper, user_role: dropzone.user_roles.find_by(name: :fun_jumper))
      end
    end
    let!(:owner_dropzone_users) do
      [public_dropzone, private_dropzone].each do |dropzone|
        create(:dropzone_user, dropzone: dropzone, user: owner, user_role: dropzone.user_roles.find_by(name: :fun_jumper))
      end
      create(:dropzone_user, dropzone: owners_dropzone, user: owner, user_role: owners_dropzone.user_roles.find_by(name: :owner))
    end

    describe "Owner can see public dropzones + dropzone they own" do
      context "when querying with no variables" do
        let!(:query_str) { query() }
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        it 'shows owned and public dropzones' do
          is_expected.to include_json(
            data: {
              dropzones: {
                edges: [owners_dropzone, public_dropzone].map do |dropzone|
                  { node: { id: dropzone.id.to_s } }
                end
              }
            }
          )
          is_expected.not_to include_json(data: { dropzones: { edges: [{ node: { id: private_dropzone.id.to_s } }] }})
        end
      end

      context "even when specifying state" do
        let!(:query_str) { query(state: ['private', 'public', 'archived']) }
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        it 'shows owned and public dropzones' do
          is_expected.to include_json(
            data: {
              dropzones: {
                edges: [owners_dropzone.reload, public_dropzone.reload].map do |dropzone|
                  { node: { id: dropzone.id.to_s } }
                end
              }
            }
          )
          is_expected.not_to include_json(data: { dropzones: { edges: [{ node: { id: private_dropzone.id.to_s } }] }})
        end
      end
    end

    def query(state: nil)
      enum_states = 'null'
      enum_states = "[#{state.join(',')}]" if state.present?
      <<~GQL
        query {
          dropzones(state: #{enum_states}) {
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
