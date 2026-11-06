# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: payments, activity and meta" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let(:other_operator) { create(:operator, state: "public") }

  def order_variables(buyer:, seller:, amount: 25, **extra)
    { buyer: buyer.to_gid_param, seller: seller.to_gid_param, operator: operator.id, title: "Funds", amountCents: (amount * 100).round }.merge(extra)
  end

  describe "CreateOrder" do
    before { operator.update!(credits: 1000) }

    it "lets staff with createUserTransaction add funds to a member" do
      json = nil
      expect do
        json = client_operation("CreateOrder", variables: order_variables(buyer: operator, seller: fun_jumper), as: owner_user)
      end.to change(Order, :count).by(1)

      expect(json.dig(:data, :createOrder, :errors)).to be_nil
      expect(json.dig(:data, :createOrder, :order, :amountCents)).to eq(2500)
    end

    it "rejects a non-positive amount" do
      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: operator, amount: 0), as: owner_user)

      expect(json.dig(:data, :createOrder, :errors)).to eq(["Amount must be positive"])
    end

    it "refuses a jumper adding funds from the operator" do
      json = nil
      expect do
        json = client_operation("CreateOrder", variables: order_variables(buyer: operator, seller: fun_jumper), as: user)
      end.not_to change(Order, :count)

      expect(json.dig(:data, :createOrder, :errors)).to eq(["You don't have permissions to create this order"])
    end

    it "does not let a member spend credits they do not have" do
      victim = create(:membership, operator: operator, credits: 0)
      fun_jumper.update!(credits: 0)

      client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: victim, amount: 1000), as: user)

      expect(fun_jumper.reload.credits).to be >= 0
      expect(victim.reload.credits).to eq(0)
    end

    it "does not let a member buy from a member of another operator" do
      foreign = create(:membership, operator: other_operator, credits: 0)

      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: foreign), as: user)

      expect(json.dig(:data, :createOrder, :order)).to be_nil
    end

    describe "who may move credits (BUG-008)" do
      let(:foreign_owner) { create(:user) }
      let!(:foreign_member) { create(:membership, operator: other_operator, credits: 0) }

      def order(buyer:, seller:, as:, amount: 25, **extra)
        client_operation("CreateOrder", variables: order_variables(buyer: buyer, seller: seller, amount: amount, **extra), as: as)
      end

      it "refuses an order that pays a member of another operator, and one that charges one" do
        expect { order(buyer: operator, seller: foreign_member, as: owner_user) }.not_to change(Order, :count)
        expect { order(buyer: foreign_member, seller: operator, as: owner_user) }.not_to change(Order, :count)
        expect(foreign_member.reload.credits).to eq(0)
      end

      it "refuses an order whose operator is another operator than the parties" do
        json = order(buyer: other_operator, seller: fun_jumper, as: owner_user)

        expect(json.dig(:data, :createOrder, :errors)).to eq(["The buyer and the seller must be the operator or its members"])
      end

      it "refuses transfers between members, even for staff" do
        other = create(:membership, operator: operator, credits: 0)
        fun_jumper.update!(credits: 100)

        json = order(buyer: fun_jumper, seller: other, as: owner_user)

        expect(json.dig(:data, :createOrder, :errors)).to eq(["Transfers between members are disabled"])
        expect(fun_jumper.reload.credits).to eq(100)
        expect(other.reload.credits).to eq(0)
      end

      it "does not let a jumper pay a member with credits they do not have" do
        victim = create(:membership, operator: operator, credits: 0)
        fun_jumper.update!(credits: 0)

        order(buyer: fun_jumper, seller: victim, as: user, amount: 1000)

        expect(fun_jumper.reload.credits).to eq(0)
        expect(victim.reload.credits).to eq(0)
      end

      it "refuses staff withdrawing more than a member has" do
        fun_jumper.update!(credits: 10)

        json = order(buyer: fun_jumper, seller: operator, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :fieldErrors, 0)).to include(field: "amount", message: "Not enough credits")
        expect(fun_jumper.reload.credits).to eq(10)
      end

      it "lets staff withdraw up to what a member has" do
        fun_jumper.update!(credits: 40)

        json = order(buyer: fun_jumper, seller: operator, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(15)
      end

      it "lets a member with enough credits pay the operator from their own balance" do
        fun_jumper.update!(credits: 40)

        json = order(buyer: fun_jumper, seller: operator, as: user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(15)
      end

      it "lets staff top up a member and credits the member" do
        fun_jumper.update!(credits: 0)

        json = order(buyer: operator, seller: fun_jumper, as: owner_user, amount: 25)

        expect(json.dig(:data, :createOrder, :errors)).to be_nil
        expect(fun_jumper.reload.credits).to eq(25)
      end

      it "refuses a member of another operator who is not a member here" do
        json = order(buyer: operator, seller: fun_jumper, as: foreign_owner)

        expect(json.dig(:data, :createOrder)).to be_nil.or include(errors: ["You are not a member of this operator"])
      end
    end

    it "keeps fractional amounts, in exact cents" do
      fun_jumper.update!(credits: 100)

      json = client_operation("CreateOrder", variables: order_variables(buyer: fun_jumper, seller: operator, amount: 12.5), as: owner_user)

      expect(json.dig(:data, :createOrder, :order, :amountCents)).to eq(1250)
      expect(Order.last.amount_cents).to eq(1250)
      expect(fun_jumper.reload.credits_cents).to eq(8750)
      expect(operator.reload.credits_cents).to eq(101_250)
    end

    describe "in cents" do
      before { fun_jumper.update!(credits: 100) }

      def create_order(attributes, query: "mutation($attributes: OrderInput!) { createOrder(input: { attributes: $attributes }) { errors order { amountCents } } }")
        post "/graphql",
             params: { query: query, variables: { attributes: { buyer: fun_jumper.to_gid_param, seller: operator.to_gid_param, operator: operator.id }.merge(attributes) }.to_json },
             headers: owner_user.create_new_auth_token
        response.parsed_body.with_indifferent_access
      end

      it "takes the amount in cents" do
        json = create_order({ amountCents: 1999 })

        expect(json.dig(:data, :createOrder, :order)).to eq("amountCents" => 1999)
        expect(fun_jumper.reload.credits_cents).to eq(8001)
      end

      it "needs an amount" do
        expect(create_order({}).dig(:data, :createOrder, :errors)).to eq(["An amount is needed"])
      end
    end
  end

  describe "refunds" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 12.5) }
    let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: owner, gca: owner, load_master: owner) }

    it "gives back exactly what a ticket with fractional cost charged" do
      fun_jumper.update!(credits: 100)
      slot_id = client_operation("ManifestUser",
                                 variables: {
                                   load: manifest_load.id, membership: fun_jumper.id, ticketType: ticket.id,
                                   activityType: ActivityType.allowed_for([fun_jumper]).first.id, bodyMassKg: 80,
                                 },
                                 as: owner_user).dig(:data, :createSlot, :slot, :id)

      client_operation("DeleteSlot", variables: { id: slot_id.to_i }, as: owner_user)

      expect(fun_jumper.reload.credits).to eq(100)
    end
  end

  describe "OperatorTransactions" do
    it "lists the operator's orders for staff who may read transactions" do
      client_operation("CreateOrder", variables: order_variables(buyer: operator, seller: fun_jumper), as: owner_user)

      json = client_operation("OperatorTransactions", variables: { operatorId: operator.id }, as: owner_user)

      expect(json.dig(:data, :operator, :orders, :edges).size).to eq(1)
    end

    it "returns no orders to a jumper without transaction rights" do
      client_operation("CreateOrder", variables: order_variables(buyer: operator, seller: fun_jumper), as: owner_user)

      json = client_operation("OperatorTransactions", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :operator, :orders, :edges).to_a).to eq([])
    end
  end

  describe "Activity" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
    let!(:manifest_load) { create(:load, vehicle: vehicle, pilot: owner, gca: owner, load_master: owner) }

    before do
      fun_jumper.update!(credits: 300)
      client_operation("ManifestUser",
                       variables: {
                         load: manifest_load.id, membership: fun_jumper.id, ticketType: ticket.id,
                         activityType: ActivityType.allowed_for([fun_jumper]).first.id, bodyMassKg: 80,
                       },
                       as: owner_user)
    end

    it "lists the activity of an operator" do
      json = client_operation("Activity", variables: { operator: [operator.id] }, as: owner_user)

      messages = json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }
      expect(messages).to include(a_string_matching(/manifested .* on load/i))
    end

    it "filters by level and action" do
      json = client_operation("Activity", variables: { operator: [operator.id], levels: ["error"] }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :activity, :edges)).to eq([])
    end

    it "does not show another operator's activity" do
      other_owner = create(:user)
      create(:membership, operator: other_operator, user: other_owner, user_role: other_operator.user_roles.find_by(name: "owner"))
      other_member = other_operator.memberships.first
      Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(other_member), level: :info, access_level: :user,
                                 message: "secret other operator event", resource: other_operator, action: :created,
                                 created_by: other_member, operator: other_operator)

      json = client_operation("Activity", variables: { operator: [operator.id] }, as: owner_user)

      expect(json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }).not_to include("secret other operator event")
    end

    it "does not return events of operators the caller does not belong to when no operator is given" do
      other_owner = create(:user)
      other_member = create(:membership, operator: other_operator, user: other_owner, user_role: other_operator.user_roles.find_by(name: "owner"))
      Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(other_member), level: :info, access_level: :user,
                                 message: "secret other operator event", resource: other_operator, action: :created,
                                 created_by: other_member, operator: other_operator)

      json = client_operation("Activity", variables: {}, as: user)

      expect(json.dig(:data, :activity, :edges).map { |edge| edge.dig(:node, :message) }).not_to include("secret other operator event")
    end
  end

  describe "ActivityDetails" do
    it "returns page info with the events" do
      json = client_operation("ActivityDetails", variables: { operator: [operator.id] }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :activity, :pageInfo)).to include(:hasNextPage, :endCursor)
    end

    it "requires authentication" do
      expect(client_operation("ActivityDetails", variables: { operator: [operator.id] }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "CertificationBodies" do
    it "lists the certification bodies" do
      json = client_operation("CertificationBodies", as: user)

      expect(json.dig(:data, :certificationBodies).pluck(:slug)).to include("apf")
      expect(json.dig(:data, :certificationBodies).find { |body| body[:slug] == "apf" }).to include(industry: "skydiving", verificationProvider: "apf")
    end

    it "lists the bodies of one industry" do
      CertificationBody.create!(name: "PADI", slug: "padi", industry: "generic")

      json = client_operation("CertificationBodies", variables: { industry: "SKYDIVING" }, as: user)

      expect(json.dig(:data, :certificationBodies).pluck(:slug)).to include("apf")
      expect(json.dig(:data, :certificationBodies).pluck(:slug)).not_to include("padi")
    end

    it "requires authentication" do
      expect(client_operation("CertificationBodies").dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "CertificationLevels" do
    it "lists the certification levels of a body from the lowest rank, with their rank" do
      certification_body = CertificationBody.find_by(slug: "apf")

      json = client_operation("CertificationLevels", variables: { certificationBodyId: certification_body.id }, as: user)

      levels = json.dig(:data, :certificationLevels)
      expect(levels.pluck(:name)).to eq(certification_body.certification_levels.pluck(:name))
      expect(levels.pluck(:rank)).to eq(levels.pluck(:rank).sort)
      expect(levels.first).to include(name: "No license", rank: 0, equivalenceKey: "none")
    end

    it "lists every certification level without a body" do
      json = client_operation("CertificationLevels", as: user)

      expect(json.dig(:data, :certificationLevels).size).to eq(CertificationLevel.count)
    end
  end

  describe "Qualifications" do
    let!(:rating) { create(:qualification, certification_body: CertificationBody.find_by(slug: "apf"), name: "Tandem rating") }

    it "lists the qualifications, of one body when given" do
      other = create(:qualification, certification_body: CertificationBody.create!(name: "Other", slug: "other", industry: "skydiving"))

      all = client_operation("Qualifications", as: user)
      apf = client_operation("Qualifications", variables: { certificationBodyId: rating.certification_body_id }, as: user)

      expect(all.dig(:data, :qualifications).pluck(:id)).to include(rating.id.to_s, other.id.to_s)
      expect(apf.dig(:data, :qualifications).pluck(:id)).to eq([rating.id.to_s])
      expect(apf.dig(:data, :qualifications, 0, :certificationBody)).to include(slug: "apf")
    end

    it "requires authentication" do
      expect(client_operation("Qualifications").dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "AddUserQualification" do
    let(:body) { CertificationBody.find_by(slug: "apf") }
    let!(:rating) { create(:qualification, certification_body: body, name: "Tandem rating") }
    let(:newcomer) { create(:user) }

    it "records the qualification of the caller with its number and expiry" do
      json = client_operation("AddUserQualification", variables: { qualificationId: rating.id, number: "T-9", expiresAt: 1.year.from_now.iso8601 }, as: newcomer)

      expect(json.dig(:data, :addUserQualification, :errors)).to be_blank
      expect(json.dig(:data, :addUserQualification, :userQualification)).to include(name: "Tandem rating", number: "T-9", current: true)
      expect(newcomer.reload.qualified_for?(rating)).to be true
    end

    it "joins the caller to the body of the qualification, without a level" do
      client_operation("AddUserQualification", variables: { qualificationId: rating.id, number: "T-9" }, as: newcomer)

      held = UserCertification.find_by!(user: newcomer, certification_body: body)
      expect(held.certification_level_id).to be_nil
    end

    it "updates the number and the expiry when it is recorded again" do
      client_operation("AddUserQualification", variables: { qualificationId: rating.id, number: "T-9", expiresAt: 1.year.from_now.iso8601 }, as: newcomer)

      expect do
        client_operation("AddUserQualification", variables: { qualificationId: rating.id, number: "T-10", expiresAt: 1.day.ago.iso8601 }, as: newcomer)
      end.not_to change(UserQualification, :count)

      expect(newcomer.reload.user_qualifications.first).to have_attributes(number: "T-10")
      expect(newcomer.qualified_for?(rating)).to be false
    end

    it "reports a qualification that does not exist" do
      json = client_operation("AddUserQualification", variables: { qualificationId: 0 }, as: user)

      expect(json.dig(:data, :addUserQualification, :errors)).to eq(["Qualification not found"])
    end

    it "requires authentication" do
      expect(client_operation("AddUserQualification", variables: { qualificationId: rating.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "ActivityTypes" do
    it "lists every jump type" do
      json = client_operation("ActivityTypes", as: user)

      expect(json.dig(:data, :activityTypes).size).to eq(ActivityType.count)
    end

    it "restricts jump types to what the given members may jump" do
      json = client_operation("ActivityTypes", variables: { allowedForMembershipIds: [fun_jumper.id] }, as: user)

      expect(json.dig(:data, :activityTypes).pluck(:id)).to match_array(ActivityType.allowed_for([fun_jumper]).map { |j| j.id.to_s })
    end
  end

  describe "AllowedActivityTypes" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }

    it "returns the allowed jump types and ticket types of an operator" do
      json = client_operation("AllowedActivityTypes", variables: { operatorId: operator.id, allowedForMembershipIds: [fun_jumper.id] }, as: user)

      expect(json.dig(:data, :operator, :allowedActivityTypes).pluck(:id)).to match_array(ActivityType.allowed_for([fun_jumper]).map { |j| j.id.to_s })
      expect(json.dig(:data, :operator, :ticketTypes).pluck(:name)).to include("Height")
      expect(json.dig(:data, :activityTypes)).to be_present
    end

    it "limits ticket types to public ones when isPublic is set" do
      ticket.update!(allow_manifesting_self: false)

      json = client_operation("AllowedActivityTypes", variables: { operatorId: operator.id, allowedForMembershipIds: [fun_jumper.id], isPublic: true }, as: user)

      expect(json.dig(:data, :operator, :ticketTypes)).to eq([])
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
