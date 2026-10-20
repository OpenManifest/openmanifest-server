# frozen_string_literal: true

require "rails_helper"

# The documents behind the member's screens (U4.1 Today, U4.2 self-booking, U4.3 Wallet), with the member asking
RSpec.describe "Client operations: the member's screens" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500).tap { |member| %i(actAsGCA actAsLoadMaster).each { |permission| member.grant!(permission) } } }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let!(:ticket_type) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
  let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, name: "Existing", max_slots: 10) }
  let(:activity) { ActivityType.allowed_for([fun_jumper]).first }

  before do
    operator.update!(settings: operator.settings.merge("require_equipment_inspection" => false, "require_equipment_in_service" => false))
    fun_jumper.update!(credits: 300)
  end

  def manifest!(load: manifest_load)
    json = client_operation("ManifestUser", variables: { load: load.id, membership: fun_jumper.id, ticketType: ticket_type.id, activityType: activity.id, bodyMassKg: 80 }, as: user)
    Slot.find(json.dig(:data, :createSlot, :slot, :id))
  end

  describe "Today" do
    def today(**variables)
      client_operation("Today", variables: { operatorId: operator.id, date: Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }.merge(variables), as: user)
    end

    it "gives the member's credit and readiness, and the loads of the day with their places" do
      slot = manifest!

      json = today

      expect(json[:errors]).to be_nil
      me = json.dig(:data, :operator, :currentUser)
      expect(me).to include(id: fun_jumper.id.to_s, creditsCents: 26_000)
      expect(me.dig(:eligibility, :rules)).to all(include(:code, :ok, :status))
      loads = json.dig(:data, :loads, :edges).pluck(:node)
      expect(loads.pluck(:id)).to eq([manifest_load.id.to_s])
      expect(loads.first[:slots].map { |node| node.dig(:membership, :id) }).to eq([fun_jumper.id.to_s])
      expect(loads.first[:slots].first[:id]).to eq(slot.id.to_s)
    end
  end

  describe "SelfBooking" do
    def self_booking(**variables)
      client_operation("SelfBooking", variables: { operatorId: operator.id, loadId: manifest_load.id }.merge(variables), as: user)
    end

    it "gives the member their own readiness for the load, and what they flew last" do
      flown = create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 10)
      create(:slot, load: flown, membership: fun_jumper, operator: operator, ticket_type: ticket_type, activity_type: activity)
      flown.update_columns(state: Load.states[:completed], departed_at: 1.hour.ago, completed_at: 30.minutes.ago)

      json = self_booking

      expect(json[:errors]).to be_nil
      me = json.dig(:data, :operator, :currentUser)
      expect(me).to include(id: fun_jumper.id.to_s, creditsCents: 30_000)
      expect(me.dig(:eligibility, :ready)).to be(true)
      expect(me.dig(:lastSlot, :ticketType, :id)).to eq(ticket_type.id.to_s)
      expect(me.dig(:lastSlot, :load, :id)).to eq(flown.id.to_s)
    end

    it "says what stops the member, and has no last slot for one who has not flown" do
      fun_jumper.update!(credits: 0)
      operator.update!(settings: operator.settings.merge("require_credits" => true, "allow_negative_credits" => false))

      me = self_booking.dig(:data, :operator, :currentUser)

      expect(me[:lastSlot]).to be_nil
      expect(me.dig(:eligibility, :rules).find { |rule| rule[:code] == "credits" }).to include(ok: false, status: "FAIL")
    end
  end

  describe "Wallet" do
    def wallet(**variables)
      client_operation("Wallet", variables: { membershipId: fun_jumper.id, first: 30 }.merge(variables), as: user)
    end

    it "gives the balance, and the order of a booked jump held until it is flown" do
      manifest!

      json = wallet

      expect(json[:errors]).to be_nil
      membership = json.dig(:data, :membership)
      expect(membership).to include(id: fun_jumper.id.to_s, creditsCents: 26_000)
      order = membership.dig(:orders, :edges, 0, :node)
      expect(order).to include(state: "pending", amountCents: 4000)
      expect(order.dig(:buyer, :id)).to eq(fun_jumper.id.to_s)
      expect(order.dig(:seller, :__typename)).to eq("Operator")
      mine = order[:receipts].flat_map { |receipt| receipt[:transactions] }.select { |transaction| transaction.dig(:receiver, :id) == fun_jumper.id.to_s }
      expect(mine).to contain_exactly(include(transactionType: "purchase", amountCents: -4000, status: "reserved"))
    end

    it "gives the balance back and marks the order refunded when the member comes off the load" do
      slot = manifest!
      client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

      membership = wallet.dig(:data, :membership)

      expect(membership[:creditsCents]).to eq(30_000)
      expect(membership.dig(:orders, :edges, 0, :node, :state)).to eq("refunded")
    end

    it "pages the orders, newest first" do
      first = manifest!
      client_operation("DeleteSlot", variables: { id: first.id }, as: owner_user)
      manifest!

      page = wallet(first: 1).dig(:data, :membership, :orders)

      expect(page[:edges].size).to eq(1)
      expect(page.dig(:edges, 0, :node, :state)).to eq("pending")
      expect(page.dig(:pageInfo, :hasNextPage)).to be(true)
    end

    it "does not give another member's orders to a member" do
      manifest!
      other = create(:membership, operator: operator, user: create(:user))

      json = client_operation("Wallet", variables: { membershipId: fun_jumper.id, first: 30 }, as: other.user)

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("FORBIDDEN")
      expect(json.dig(:data, :membership)).to be_nil
    end
  end
end
