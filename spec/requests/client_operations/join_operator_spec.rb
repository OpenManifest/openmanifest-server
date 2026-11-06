# frozen_string_literal: true

require "rails_helper"

# P6.4: permission checks never write, users join an operator explicitly (BUG-005, BUG-089)
RSpec.describe "Joining an operator" do
  let(:operator) { create(:operator, state: "public") }
  let(:private_operator) { create(:operator, state: "private") }
  let(:user) { create(:user) }

  def join(dz, as:)
    client_operation("JoinOperator", variables: { operator: dz.id }, as: as)
  end

  describe "User#can?" do
    it "is false without a membership and creates no rows" do
      expect { expect(user.can?(:readLoad, operator_id: operator.id)).to be(false) }.not_to change(Membership, :count)
    end

    it "uses the role of an existing membership" do
      create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by(name: "owner"))

      expect(user.can?(:updateOperator, operator_id: operator.id)).to be(true)
    end

    it "ignores a membership that was removed" do
      member = create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by(name: "owner"))
      member.discard

      expect(user.can?(:updateOperator, operator_id: operator.id)).to be(false)
    end
  end

  describe "operator { currentUser }" do
    let(:query) { "query($id: ID!) { operator(id: $id) { currentUser { id } } }" }

    it "is null for a user who has not joined, and nothing is created" do
      expect do
        post "/graphql", params: { query: query, variables: { id: operator.id }.to_json }, headers: user.create_new_auth_token
      end.not_to change(Membership, :count)

      expect(response.parsed_body.dig("data", "operator", "currentUser")).to be_nil
    end
  end

  describe "joinOperator" do
    it "makes the caller a member of a public operator with the default role" do
      json = nil
      expect { json = join(operator, as: user) }.to change { operator.memberships.where(user: user).count }.from(0).to(1)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :joinOperator, :membership, :id)).to eq(operator.memberships.find_by(user: user).id.to_s)
      expect(operator.memberships.find_by(user: user).user_role).to eq(operator.user_roles.default)
    end

    it "is idempotent" do
      first = join(operator, as: user).dig(:data, :joinOperator, :membership, :id)

      expect { @second = join(operator, as: user).dig(:data, :joinOperator, :membership, :id) }.not_to change(Membership, :count)
      expect(@second).to eq(first)
    end

    it "records who joined in the operator's activity" do
      expect { join(operator, as: user) }.to change { Activity::Event.where(operator: operator).count }.by(1)
    end

    it "refuses a private operator" do
      json = nil
      expect { json = join(private_operator, as: user) }.not_to change(Membership, :count)

      expect(json.dig(:data, :joinOperator, :errors)).to eq(["This operator cannot be joined"])
    end

    it "lets a moderator join a private operator" do
      moderator = create(:user, moderation_role: :moderator)

      expect { join(private_operator, as: moderator) }.to change { private_operator.memberships.where(user: moderator).count }.by(1)
    end

    it "does not let a member of a private operator lose or duplicate their membership" do
      create(:membership, operator: private_operator, user: user, user_role: private_operator.user_roles.find_by(name: "owner"))

      expect { join(private_operator, as: user) }.not_to change(Membership, :count)
    end

    context "after the membership was archived" do
      let!(:previous) do
        create(:membership, operator: operator, user: user, user_role: operator.user_roles.find_by(name: "admin"), credits: 75).tap do |member|
          member.grant!(:actAsPilot)
          member.discard
        end
      end

      it "restores the membership instead of creating a second one" do
        json = nil
        expect { json = join(operator, as: user) }.not_to change(Membership, :count)

        expect(json.dig(:data, :joinOperator, :errors)).to be_nil
        expect(previous.reload).not_to be_discarded
        expect(json.dig(:data, :joinOperator, :membership, :id)).to eq(previous.id.to_s)
      end

      it "gives the default role back and drops the permissions granted to the member, but keeps the credits" do
        join(operator, as: user)

        previous.reload
        expect(previous.user_role.name).to eq(Membership.new(operator: operator, user: user).user_role.name)
        expect(previous.user_role.name).not_to eq("admin")
        expect(previous.permissions).to be_empty
        expect(previous.credits).to eq(75)
      end
    end

    it "answers an unknown operator with an error" do
      json = client_operation("JoinOperator", variables: { operator: 0 }, as: user)

      expect(json.dig(:data, :joinOperator, :errors)).to eq(["This operator cannot be joined"])
    end

    it "needs a logged in user" do
      expect(client_operation("JoinOperator", variables: { operator: operator.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end
end
