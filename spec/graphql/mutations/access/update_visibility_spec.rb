# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Access::UpdateVisibility, type: :request do
    let!(:operator) { create(:operator, state: :private, credits: 50) }
    let!(:moderator) do
      create(
        :membership,
        operator: operator,
        user: create(:user, moderation_role: :moderator)
      )
    end
    let!(:user) do
      create(
        :membership,
        operator: operator,
        user: create(:user, moderation_role: :user)
      )
    end
    let!(:owner) do
      create(
        :membership,
        operator: operator,
        user_role: operator.user_roles.find_by(name: :owner),
        user: create(:user, moderation_role: :user)
      )
    end

    describe "Moderator" do
      context "can unpublish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: moderator.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :unpublish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "private" } } }) }
      end

      context "can request review" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: moderator.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :request_publication
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "in_review" } } }) }
      end

      context "can publish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: moderator.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :publish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "public" } } }) }
      end
    end

    describe "Owner" do
      context "can unpublish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :unpublish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "private" } } }) }
      end

      context "can request review" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :request_publication
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "in_review" } } }) }
      end

      context "can not publish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: owner.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.reload.id,
            event: :publish
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s } } }) }
        it { is_expected.to include_json(data: { updateVisibility: { errors: ["You cannot perform this action"] } }) }
      end
    end

    describe "User" do
      context "can not unpublish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: user.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :unpublish
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { operator: { state: "private" } } }) }
        it { is_expected.to include_json(data: { updateVisibility: { errors: ["You cannot perform this action"] } }) }
      end

      context "can not request review" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: user.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :request_publication
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { operator: { state: "in_review" } } }) }
        it { is_expected.to include_json(data: { updateVisibility: { errors: ["You cannot perform this action"] } }) }
      end

      context "can not publish" do
        subject do
          post "/graphql",
               params: { query: query_str },
               headers: user.user.create_new_auth_token
          JSON.parse(response.body, symbolize_names: true)
        end

        let(:query_str) do
          query(
            id: operator.id,
            event: :publish
          )
        end

        it {
          is_expected.not_to include_json(data: { updateVisibility: { operator: { id: operator.id.to_s, state: "public" } } })
        }
        it { is_expected.to include_json(data: { updateVisibility: { errors: ["You cannot perform this action"] } }) }
      end
    end

    def query(id:, event:)
      <<~GQL
        mutation {
          updateVisibility(
            input: {
              operator: "#{id}",
              event: #{event}
            }
          ) {
            operator {
              id
              state
            }
            errors
          }
        }
      GQL
    end
  end
end
