# frozen_string_literal: true

require "rails_helper"

# BUG-048: the API gives and takes cents (the units fields stay for older clients), and wallets move by exact cents
RSpec.describe "Money in the API" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }

  def graphql(query, variables = {}, as: owner_user)
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  describe "ticket types and add-ons" do
    let(:create_ticket) { "mutation($attributes: TicketTypeInput!) { createTicketType(input: { attributes: $attributes }) { errors ticketType { id cost costCents } } }" }
    let(:update_ticket) { "mutation($id: Int!, $attributes: TicketTypeInput!) { updateTicketType(input: { id: $id, attributes: $attributes }) { errors ticketType { cost costCents } } }" }

    it "creates a ticket type with a price in cents" do
      json = graphql(create_ticket, { attributes: { name: "Height", dropzoneId: dropzone.id, costCents: 1999, altitude: 14_000 } })

      expect(json.dig(:data, :createTicketType, :ticketType)).to include(costCents: 1999, cost: 19.99)
      expect(TicketType.last.cost_cents).to eq(1999)
    end

    it "still takes the price in whole units" do
      json = graphql(create_ticket, { attributes: { name: "Height", dropzoneId: dropzone.id, cost: 12.5, altitude: 14_000 } })

      expect(json.dig(:data, :createTicketType, :ticketType)).to include(costCents: 1250, cost: 12.5)
    end

    it "uses the cents when both are sent" do
      json = graphql(create_ticket, { attributes: { name: "Height", dropzoneId: dropzone.id, cost: 99, costCents: 1000, altitude: 14_000 } })

      expect(json.dig(:data, :createTicketType, :ticketType, :costCents)).to eq(1000)
    end

    it "updates the price in cents" do
      ticket = create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40)

      json = graphql(update_ticket, { id: ticket.id, attributes: { costCents: 4150 } })

      expect(json.dig(:data, :updateTicketType, :ticketType)).to include(costCents: 4150, cost: 41.5)
    end

    it "prices add-ons in cents" do
      query = "mutation($attributes: ExtraInput!) { createExtra(input: { attributes: $attributes }) { errors extra { cost costCents } } }"

      json = graphql(query, { attributes: { name: "Video", dropzoneId: dropzone.id, costCents: 505 } })

      expect(json.dig(:data, :createExtra, :extra)).to include(costCents: 505, cost: 5.05)
    end

    it "lists the price of a ticket in both" do
      create(:ticket_type, dropzone: dropzone, name: "Height", cost: 12.5)

      json = client_operation("TicketTypes", variables: { dropzone: dropzone.id }, as: owner_user)

      expect(json.dig(:data, :ticketTypes, 0)).to include(cost: 12.5)
      expect(TicketType.where(dropzone: dropzone).pluck(:cost_cents)).to eq([1250])
    end
  end

  describe "wallets" do
    it "gives a member's credits in cents and units" do
      fun_jumper.update!(credits: 12.5)

      json = graphql("query($id: ID!) { dropzoneUser(id: $id) { credits creditsCents } }", { id: fun_jumper.id })

      expect(json.dig(:data, :dropzoneUser)).to include("credits" => 12.5, "creditsCents" => 1250)
    end

    it "keeps a member without a wallet without one" do
      fun_jumper.update!(credits: nil)

      json = graphql("query($id: ID!) { dropzoneUser(id: $id) { credits creditsCents hasCredits } }", { id: fun_jumper.id })

      expect(json.dig(:data, :dropzoneUser)).to include("credits" => nil, "creditsCents" => nil, "hasCredits" => false)
    end

    it "lets staff set a member's credits in cents" do
      query = "mutation($id: ID!, $attributes: DropzoneUserInput!) { updateDropzoneUser(input: { dropzoneUser: $id, attributes: $attributes }) { errors dropzoneUser { credits creditsCents } } }"

      json = graphql(query, { id: fun_jumper.id, attributes: { creditsCents: 12_345 } })

      expect(json.dig(:data, :updateDropzoneUser, :dropzoneUser)).to include("credits" => 123.45, "creditsCents" => 12_345)
      expect(fun_jumper.reload.credits_cents).to eq(12_345)
    end
  end

  describe "manifesting and refunding" do
    let!(:ticket) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 12.5) }
    let!(:video) { Extra.create!(dropzone: dropzone, name: "Video", cost: 0.1).tap { |extra| ticket.extras << extra } }
    let!(:coach) { Extra.create!(dropzone: dropzone, name: "Coach", cost: 0.2).tap { |extra| ticket.extras << extra } }
    let!(:manifest_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner) }

    def manifest
      json = client_operation("ManifestUser",
                              variables: {
                                load: manifest_load.id, dropzoneUser: fun_jumper.id, ticketType: ticket.id, extras: [video.id, coach.id],
                                jumpType: JumpType.allowed_for([fun_jumper]).first.id, exitWeight: 80,
                              },
                              as: owner_user)
      Slot.find(json.dig(:data, :createSlot, :slot, :id))
    end

    before do
      fun_jumper.update!(credits: 100)
      dropzone.update!(credits: 50)
    end

    it "charges exact cents for a ticket with add-ons" do
      slot = manifest

      expect(slot.cost_cents).to eq(1280)
      expect(slot.order.amount_cents).to eq(1280)
      expect(slot.order.receipts.first.amount_cents).to eq(1280)
      expect(slot.order.transactions.pluck(:amount_cents)).to match_array([1280, -1280])
      expect(fun_jumper.reload.credits_cents).to eq(8720)
      expect(dropzone.reload.credits_cents).to eq(6280)
    end

    it "gives back exactly what was charged, to the cent" do
      slot = manifest

      client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)

      expect(fun_jumper.reload.credits_cents).to eq(10_000)
      expect(dropzone.reload.credits_cents).to eq(5000)
    end

    it "keeps the sum of the wallets of the member and the dropzone whatever happens" do
      total = -> { fun_jumper.reload.credits_cents + dropzone.reload.credits_cents }
      before_total = total.call

      slot = manifest
      expect(total.call).to eq(before_total)
      client_operation("DeleteSlot", variables: { id: slot.id }, as: owner_user)
      expect(total.call).to eq(before_total)
    end

    it "shows the cents of the slot and its order" do
      manifest
      json = graphql("query($id: ID!) { load(id: $id) { slots { cost costCents } } }", { id: manifest_load.id })

      expect(json.dig(:data, :load, :slots, 0)).to include("cost" => 12.8, "costCents" => 1280)
    end

    it "counts revenue in cents" do
      manifest
      manifest_load.update!(dispatch_at: 10.minutes.from_now)
      manifest_load.dispatch
      client_operation("FinalizeLoad", variables: { id: manifest_load.id, state: "landed" }, as: owner_user)

      statistics = graphql("query($id: ID!) { dropzone(id: $id) { statistics { revenueCentsCount } } }", { id: dropzone.id })

      expect(statistics.dig(:data, :dropzone, :statistics, :revenueCentsCount)).to eq(1280)
    end
  end
end
