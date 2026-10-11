# frozen_string_literal: true

require "rails_helper"

# P6.9: subscriptions check membership of what they follow (BUG-011)
RSpec.describe "Subscription authorization" do
  let(:operator) { create(:operator, state: "public") }
  let(:other_operator) { create(:operator, state: "public") }
  let(:plane) { create(:plane, operator: operator, max_slots: 16) }
  let!(:owner) { create(:membership, operator: operator, user: create(:user), user_role: operator.user_roles.find_by(name: "owner")) }
  let!(:member) { create(:membership, operator: operator, user: create(:user), user_role: operator.user_roles.find_by(name: "fun_jumper")) }
  let!(:student) { create(:membership, operator: operator, user: create(:user), user_role: operator.user_roles.find_by(name: "student")) }
  let!(:foreign) { create(:membership, operator: other_operator, user: create(:user), user_role: other_operator.user_roles.find_by(name: "owner")) }
  let!(:load_record) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }
  let(:channel) { Struct.new(:params) { def stream_from(*); end }.new({ "channelId" => "subscription-authorization-spec" }) }

  def subscribe(query, variables, as:)
    DzSchema.execute(query: query, variables: variables,
                     context: { channel: channel, current_resource: as, access_context: AccessContext::CurrentUser.for(as) })
  end

  def refused?(result)
    result.to_h.dig("errors", 0, "extensions", "code") == "FORBIDDEN" || result.to_h["data"].nil? || result.to_h["data"].values.all?(&:nil?)
  end

  describe "loadUpdated" do
    let(:query) { "subscription($id: ID!) { loadUpdated(loadId: $id) { load { id } } }" }

    it "lets a member of the load's operator subscribe" do
      result = subscribe(query, { "id" => load_record.id.to_s }, as: member.user)

      expect(result.to_h.dig("data", "loadUpdated", "load", "id")).to eq(load_record.id.to_s)
    end

    it "refuses a member of another operator, and a user without membership" do
      expect(refused?(subscribe(query, { "id" => load_record.id.to_s }, as: foreign.user))).to be(true)
      expect(refused?(subscribe(query, { "id" => load_record.id.to_s }, as: create(:user)))).to be(true)
    end
  end

  describe "loadCreated" do
    let(:query) { "subscription($id: ID!) { loadCreated(operatorId: $id) { load { id } } }" }

    it "lets a member subscribe to the operator and refuses everybody else" do
      expect(subscribe(query, { "id" => operator.id.to_s }, as: member.user).to_h["errors"]).to be_nil
      expect(subscribe(query, { "id" => operator.id.to_s }, as: foreign.user).to_h.dig("errors", 0, "extensions", "code")).to eq("FORBIDDEN")
      expect(subscribe(query, { "id" => operator.id.to_s }, as: create(:user)).to_h.dig("errors", 0, "extensions", "code")).to eq("FORBIDDEN")
    end
  end

  describe "userUpdated" do
    let(:query) { "subscription($id: ID!) { userUpdated(membershipId: $id) { membership { id } } }" }

    it "lets a member follow themselves" do
      result = subscribe(query, { "id" => student.id.to_s }, as: student.user)

      expect(result.to_h.dig("data", "userUpdated", "membership", "id")).to eq(student.id.to_s)
    end

    it "lets somebody with readUser follow another member" do
      result = subscribe(query, { "id" => student.id.to_s }, as: owner.user)

      expect(result.to_h.dig("data", "userUpdated", "membership", "id")).to eq(student.id.to_s)
    end

    it "refuses somebody without readUser, a member of another operator and a stranger" do
      expect(subscribe(query, { "id" => owner.id.to_s }, as: student.user).to_h.dig("errors", 0, "extensions", "code")).to eq("FORBIDDEN")
      expect(subscribe(query, { "id" => student.id.to_s }, as: foreign.user).to_h.dig("errors", 0, "extensions", "code")).to eq("FORBIDDEN")
      expect(subscribe(query, { "id" => student.id.to_s }, as: create(:user)).to_h.dig("errors", 0, "extensions", "code")).to eq("FORBIDDEN")
    end
  end

  it "needs a logged in user" do
    result = DzSchema.execute(query: "subscription($id: ID!) { loadUpdated(loadId: $id) { load { id } } }", variables: { "id" => load_record.id.to_s },
                              context: { channel: channel })

    expect(result.to_h["errors"]).to be_present
  end
end
