# frozen_string_literal: true

require "rails_helper"

# UB.3 over GraphQL: the slot a member last flew, and when a load was called
RSpec.describe "Last slot and call time over GraphQL", type: :request do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }

  def run(query, variables = {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: owner_user.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  def load_in(state, **attributes)
    create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, **attributes).tap { |record| record.update_columns(state: Load.states[state]) }
  end

  def fly(member, load, **attributes)
    create(:slot, load: load, membership: member, operator: operator, ticket_type: ticket, activity_type: ActivityType.allowed_for([member]).first, **attributes)
  end

  let(:member) { create(:membership, operator: operator, credits: 500) }

  # A member flies again and again
  before { operator.update!(settings: operator.settings.merge("allow_double_manifesting" => true)) }
  let(:query) { "query($id: ID!) { membership(id: $id) { id lastSlot { id bodyMassKg ticketType { id name } activityType { id } } } }" }

  describe "Membership.lastSlot" do
    it "is the slot on the most recent load that left or landed" do
      older = load_in(:completed, load_date: operator.today)
      older.update_columns(completed_at: 2.hours.ago, departed_at: 2.hours.ago)
      newer = load_in(:departed, load_date: operator.today)
      newer.update_columns(departed_at: 10.minutes.ago)
      fly(member, older, body_mass_kg: 70)
      latest = fly(member, newer, body_mass_kg: 75)

      json = run(query, id: member.id)

      expect(json.dig(:data, :membership, :lastSlot)).to include(id: latest.id.to_s, bodyMassKg: 75)
      expect(json.dig(:data, :membership, :lastSlot, :ticketType, :name)).to eq("Height")
    end

    it "ignores slots on loads that have not left, and loads that were cancelled" do
      fly(member, load_in(:open), body_mass_kg: 70)
      fly(create(:membership, operator: operator, credits: 500), load_in(:boarding), body_mass_kg: 70)
      cancelled = load_in(:cancelled)
      fly(member, cancelled, body_mass_kg: 71)

      expect(run(query, id: member.id).dig(:data, :membership, :lastSlot)).to be_nil
    end

    it "is empty for a member who has not flown" do
      expect(run(query, id: member.id).dig(:data, :membership, :lastSlot)).to be_nil
    end

    it "is looked up for a whole list in a bounded number of queries" do
      members = Array.new(8) { create(:membership, operator: operator, credits: 500) }
      landed = load_in(:completed, load_date: operator.today)
      landed.update_columns(completed_at: 1.hour.ago, departed_at: 1.hour.ago)
      members.each { |each_member| fly(each_member, landed, body_mass_kg: 70) }
      list = "query($operator: ID!) { memberships(operator: $operator, first: 50, licensed: false) { edges { node { id lastSlot { id ticketType { id name } activityType { id } } } } } }"
      Prosopite.raise = true
      Prosopite.min_n_queries = 4
      json = nil
      begin
        Prosopite.scan { json = run(list, operator: operator.id) }
      ensure
        Prosopite.raise = false
        Prosopite.min_n_queries = 2
      end

      nodes = json.dig(:data, :memberships, :edges).pluck(:node)
      expect(json[:errors]).to be_nil
      expect(nodes.count { |node| node[:lastSlot] }).to eq(8)
    end
  end

  describe "Load.calledAt" do
    it "shows when the load was called" do
      called = load_in(:open)
      called.update!(dispatch_at: 10.minutes.from_now)
      called.call!

      json = run("query($id: ID!) { load(id: $id) { id calledAt } }", id: called.id)

      expect(json.dig(:data, :load, :calledAt)).to be_present
    end

    it "is empty for a load that was not called" do
      json = run("query($id: ID!) { load(id: $id) { id calledAt } }", id: load_in(:open).id)

      expect(json.dig(:data, :load, :calledAt)).to be_nil
    end
  end
end
