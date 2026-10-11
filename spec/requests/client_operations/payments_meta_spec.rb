# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: payments, activity and meta" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let(:other_dropzone) { create(:dropzone, state: "public") }

  def order_variables(buyer:, seller:, amount: 25, **extra)
    { buyer: buyer.to_gid_param, seller: seller.to_gid_param, dropzone: dropzone.id, title: "Funds", amount: amount }.merge(extra)
  end

  describe "CreateOrder" do
    before { dropzone.update!(credits: 1000) }

    it "lets staff with createUserTransaction add funds to a member" do
      json = nil
      expect do
        json = client_operation("CreateOrder", variables: order_variables(buyer: dropzone, seller: fun_jumper), as: owner_user)
      end.to change(Order, :count).by(1)

      expect(json.dig(:data, :createOrder, :errors)).to be_nil
      expect(json.dig(:data, :createOrder, :order, :amount)).to eq(25.0)
    end

    it "rejects a non-positive amount" do
      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: dropzone, amount: 0), as: owner_user)

      expect(json.dig(:data, :createOrder, :errors)).to eq(["Amount must be positive"])
    end

    it "refuses a jumper adding funds from the dropzone" do
      json = nil
      expect do
        json = client_operation("CreateOrder", variables: order_variables(buyer: dropzone, seller: fun_jumper), as: user)
      end.not_to change(Order, :count)

      expect(json.dig(:data, :createOrder, :errors)).to eq(["You don't have permissions to create this order"])
    end

    it "does not let a member spend credits they do not have" do
      victim = create(:dropzone_user, dropzone: dropzone, credits: 0)
      fun_jumper.update!(credits: 0)

      client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: victim, amount: 1000), as: user)

      expect(fun_jumper.reload.credits).to be >= 0
      expect(victim.reload.credits).to eq(0)
    end

    it "does not let a member buy from a member of another dropzone" do
      foreign = create(:dropzone_user, dropzone: other_dropzone, credits: 0)

      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: foreign), as: user)

      expect(json.dig(:data, :createOrder, :order)).to be_nil
    end

    describe "who may move credits (BUG-008)" do
      let(:foreign_owner) { create(:user) }
      let!(:foreign_member) { create(:dropzone_user, dropzone: other_dropzone, credits: 0) }

      def order(buyer:, seller:, as:, amount: 25, **extra)
        client_operation("CreateOrder", variables: order_variables(buyer: buyer, seller: seller, amount: amount, **extra), as: as)
      end

      it "refuses an order that pays a member of another dropzone, and one that charges one" do
        expect { order(buyer: dropzone, seller: foreign_member, as: owner_user) }.not_to change(Order, :count)
        expect { order(buyer: foreign_member, seller: dropzone, as: owner_user) }.not_to change(Order, :count)
        expect(foreign_member.reload.credits).to eq(0)
      end

      it "refuses an order whose dropzone is another dropzone than the parties" do
        json = order(buyer: other_dropzone, seller: fun_jumper, as: owner_user)

        expect(json.dig(:data, :createOrder, :errors)).to eq(["The buyer and the seller must be the dropzone or its members"])
      end

      it "refuses transfers between members, even for staff" do
        other = create(:dropzone_user, dropzone: dropzone, credits: 0)
        fun_jumper.update!(credits: 100)

        json = order(buyer: fun_jumper, seller: other, as: owner_user)

        expect(json.dig(:data, :createOrder, :errors)).to eq(["Transfers between members are disabled"])
        expect(fun_jumper.reload.credits).to eq(100)
        expect(other.reload.credits).to eq(0)
      end

      it "does not let a jumper pay a member with credits they do not have" do
        victim = create(:dropzone_user, dropzone: dropzone, credits: 0)
        fun_jumper.update!(credits: 0)

        order(buyer: fun_jumper, seller: victim, as: user, amount: 1000)

        expect(fun_jumper.reload.credits).to eq(0)
        expect(victim.reload.credits).to eq(0)
      end

      it "refuses staff withdrawing more than a member has" do
        fun_jumper.update!(credits: 10)

        json = order(buyer: fun_jumper, seller: dropzone, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :fieldErrors, 0)).to include(field: "amount", message: "Not enough credits")
        expect(fun_jumper.reload.credits).to eq(10)
      end

      it "lets staff withdraw up to what a member has" do
        fun_jumper.update!(credits: 40)

        json = order(buyer: fun_jumper, seller: dropzone, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(15)
      end

      it "lets a member with enough credits pay the dropzone from their own balance" do
        fun_jumper.update!(credits: 40)

        json = order(buyer: fun_jumper, seller: dropzone, as: user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(15)
      end

      it "lets staff top up a member and credits the member" do
        fun_jumper.update!(credits: 0)

        json = order(buyer: dropzone, seller: fun_jumper, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(25)
      end

      it "refuses a member of another dropzone who is not a member here" do
        json = order(buyer: dropzone, seller: fun_jumper, as: foreign_owner)

        expect(json.dig(:data, :createOrder)).to be_nil.or include(errors: ["You are not a member of this dropzone"])
      end
    end

    it "keeps fractional amounts" do
      pending "BUG-048: money is stored and refunded as integers and floats; fractional amounts are truncated"

      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: dropzone, amount: 12.5), as: owner_user)

      expect(json.dig(:data, :createOrder, :order, :amount)).to eq(12.5)
    end
  end

  describe "refunds" do
    let!(:ticket) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 12.5) }
    let!(:manifest_load) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }

    it "gives back exactly what a ticket with fractional cost charged" do
      pending "BUG-048: Refund updates credits with amount_cents / 100 (integer division)"
      fun_jumper.update!(credits: 100)
      slot_id = client_operation("ManifestUser",
                                 variables: {
                                   load: manifest_load.id, dropzoneUser: fun_jumper.id, ticketType: ticket.id,
                                   jumpType: JumpType.allowed_for([fun_jumper]).first.id, exitWeight: 80,
                                 },
                                 as: owner_user).dig(:data, :createSlot, :slot, :id)

      client_operation("DeleteSlot", variables: { id: slot_id.to_i }, as: owner_user)

      expect(fun_jumper.reload.credits).to eq(100)
    end
  end

  describe "DropzoneTransactions" do
    it "lists the dropzone's orders for staff who may read transactions" do
      client_operation("CreateOrder", variables: order_variables(buyer: dropzone, seller: fun_jumper), as: owner_user)

      json = client_operation("DropzoneTransactions", variables: { dropzoneId: dropzone.id }, as: owner_user)

      expect(json.dig(:data, :dropzone, :orders, :edges).size).to eq(1)
    end

    it "returns no orders to a jumper without transaction rights" do
      client_operation("CreateOrder", variables: order_variables(buyer: dropzone, seller: fun_jumper), as: owner_user)

      json = client_operation("DropzoneTransactions", variables: { dropzoneId: dropzone.id }, as: user)

      expect(json.dig(:data, :dropzone, :orders, :edges).to_a).to eq([])
    end
  end

  describe "Activity" do
    let!(:ticket) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
    let!(:manifest_load) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }

    before do
      fun_jumper.update!(credits: 300)
      client_operation("ManifestUser",
                       variables: {
                         load: manifest_load.id, dropzoneUser: fun_jumper.id, ticketType: ticket.id,
                         jumpType: JumpType.allowed_for([fun_jumper]).first.id, exitWeight: 80,
                       },
                       as: owner_user)
    end

    it "lists the activity of a dropzone" do
      json = client_operation("Activity", variables: { dropzone: [dropzone.id] }, as: owner_user)

      messages = json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }
      expect(messages).to include(a_string_matching(/manifested .* on load/i))
    end

    it "filters by level and action" do
      json = client_operation("Activity", variables: { dropzone: [dropzone.id], levels: ["error"] }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :activity, :edges)).to eq([])
    end

    it "does not show another dropzone's activity" do
      other_owner = create(:user)
      create(:dropzone_user, dropzone: other_dropzone, user: other_owner, user_role: other_dropzone.user_roles.find_by(name: "owner"))
      other_member = other_dropzone.dropzone_users.first
      Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(other_member), level: :info, access_level: :user,
                                 message: "secret other dropzone event", resource: other_dropzone, action: :created,
                                 created_by: other_member, dropzone: other_dropzone)

      json = client_operation("Activity", variables: { dropzone: [dropzone.id] }, as: owner_user)

      expect(json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }).not_to include("secret other dropzone event")
    end

    it "does not return events of dropzones the caller does not belong to when no dropzone is given" do
      other_owner = create(:user)
      other_member = create(:dropzone_user, dropzone: other_dropzone, user: other_owner, user_role: other_dropzone.user_roles.find_by(name: "owner"))
      Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(other_member), level: :info, access_level: :user,
                                 message: "secret other dropzone event", resource: other_dropzone, action: :created,
                                 created_by: other_member, dropzone: other_dropzone)

      json = client_operation("Activity", variables: {}, as: user)

      expect(json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }).not_to include("secret other dropzone event")
    end
  end

  describe "ActivityDetails" do
    it "returns page info with the events" do
      json = client_operation("ActivityDetails", variables: { dropzone: [dropzone.id] }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :activity, :pageInfo)).to include(:hasNextPage, :endCursor)
    end

    it "requires authentication" do
      expect(client_operation("ActivityDetails", variables: { dropzone: [dropzone.id] }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Federations" do
    it "lists the federations" do
      json = client_operation("Federations", as: user)

      expect(json.dig(:data, :federations).pluck(:slug)).to include("apf")
    end

    it "requires authentication" do
      expect(client_operation("Federations").dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Licenses" do
    it "lists the licenses of a federation" do
      federation = Federation.find_by(slug: "apf")

      json = client_operation("Licenses", variables: { federationId: federation.id }, as: user)

      expect(json.dig(:data, :licenses).pluck(:name)).to match_array(federation.licenses.pluck(:name))
    end

    it "lists every license without a federation" do
      json = client_operation("Licenses", as: user)

      expect(json.dig(:data, :licenses).size).to eq(License.count)
    end
  end

  describe "JumpTypes" do
    it "lists every jump type" do
      json = client_operation("JumpTypes", as: user)

      expect(json.dig(:data, :jumpTypes).size).to eq(JumpType.count)
    end

    it "restricts jump types to what the given members may jump" do
      json = client_operation("JumpTypes", variables: { allowedForDropzoneUserIds: [fun_jumper.id] }, as: user)

      expect(json.dig(:data, :jumpTypes).pluck(:id)).to match_array(JumpType.allowed_for([fun_jumper]).map { |j| j.id.to_s })
    end
  end

  describe "AllowedJumpTypes" do
    let!(:ticket) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }

    it "returns the allowed jump types and ticket types of a dropzone" do
      json = client_operation("AllowedJumpTypes", variables: { dropzoneId: dropzone.id, allowedForDropzoneUserIds: [fun_jumper.id] }, as: user)

      expect(json.dig(:data, :dropzone, :allowedJumpTypes).pluck(:id)).to match_array(JumpType.allowed_for([fun_jumper]).map { |j| j.id.to_s })
      expect(json.dig(:data, :dropzone, :ticketTypes).pluck(:name)).to include("Height")
      expect(json.dig(:data, :jumpTypes)).to be_present
    end

    it "limits ticket types to public ones when isPublic is set" do
      ticket.update!(allow_manifesting_self: false)

      json = client_operation("AllowedJumpTypes", variables: { dropzoneId: dropzone.id, allowedForDropzoneUserIds: [fun_jumper.id], isPublic: true }, as: user)

      expect(json.dig(:data, :dropzone, :ticketTypes)).to eq([])
    end
  end

  describe "AddressToLocation" do
    it "returns the geocoded location" do
      result = instance_double(Geokit::GeoLoc, success: true, lat: -33.86, lng: 151.2, full_address: "Sydney NSW, Australia")
      allow(Geokit::Geocoders::GoogleGeocoder).to receive(:geocode).with("Sydney").and_return(result)

      json = client_operation("AddressToLocation", variables: { search: "Sydney" }, as: user)

      expect(json.dig(:data, :geocode)).to include(lat: -33.86, lng: 151.2, formattedString: "Sydney NSW, Australia")
    end

    it "returns null when nothing is found" do
      allow(Geokit::Geocoders::GoogleGeocoder).to receive(:geocode).and_return(instance_double(Geokit::GeoLoc, success: false))

      expect(client_operation("AddressToLocation", variables: { search: "zzzz" }, as: user).dig(:data, :geocode)).to be_nil
    end
  end
end
