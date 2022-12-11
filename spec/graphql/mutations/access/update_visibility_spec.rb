# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Mutations::Access::UpdateVisibility, type: :request do
    let!(:dropzone) { create(:dropzone, state: :private, credits: 50) }
    let!(:moderator) do
      create(
        :dropzone_user,
        dropzone: dropzone,
        user: create(:user, moderation_role: :moderator)
      )
    end
    let!(:user) do
      create(
        :dropzone_user,
        dropzone: dropzone,
        user: create(:user, moderation_role: :user)
      )
    end
    let!(:owner) do
      create(
        :dropzone_user,
        dropzone: dropzone,
        user_role: dropzone.user_roles.find_by(name: :owner),
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
            id: dropzone.id,
            event: :unpublish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "private" } } }) }
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
            id: dropzone.id,
            event: :request_publication
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "in_review" } } }) }
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
            id: dropzone.id,
            event: :publish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "public" } } }) }
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
            id: dropzone.id,
            event: :unpublish
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "private" } } }) }
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
            id: dropzone.id,
            event: :request_publication
          )
        end

        it { is_expected.to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "in_review" } } }) }
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
            id: dropzone.reload.id,
            event: :publish
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s } } }) }
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
            id: dropzone.id,
            event: :unpublish
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { dropzone: { state: "private" } } }) }
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
            id: dropzone.id,
            event: :request_publication
          )
        end

        it { is_expected.not_to include_json(data: { updateVisibility: { dropzone: { state: "in_review" } } }) }
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
            id: dropzone.id,
            event: :publish
          )
        end

        it {
          is_expected.not_to include_json(data: { updateVisibility: { dropzone: { id: dropzone.id.to_s, state: "public" } } })
        }
        it { is_expected.to include_json(data: { updateVisibility: { errors: ["You cannot perform this action"] } }) }
      end
    end

    def query(id:, event:)
      <<~GQL
        mutation {
          updateVisibility(
            input: {
              dropzone: "#{id}",
              event: #{event}
            }
          ) {
            dropzone {
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
