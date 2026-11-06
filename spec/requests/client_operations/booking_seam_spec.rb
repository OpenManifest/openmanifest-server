# frozen_string_literal: true

require "rails_helper"

# P7.17: what a booking needs of the manifest. A load can be scheduled for a day ahead and keeps when it left and landed; a
# slot can be paid already; the template says how bookings reach the manifest.
RSpec.describe "Booking seam", type: :request do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500).tap { |member| %i(actAsGCA actAsLoadMaster).each { |permission| member.grant!(permission) } } }
  let!(:pilot) { create(:membership, operator: operator).tap { |member| member.grant!(:actAsPilot) } }
  let(:today) { operator.today }

  def create_load(**variables)
    client_operation("CreateLoad", variables: { vehicle: vehicle.id, pilot: pilot.id, gca: owner.id, maxSlots: 8 }.merge(variables), as: owner_user)
  end

  def load_days(**variables)
    client_operation("Loads", variables: { operator: operator.id }.merge(variables), as: owner_user).dig(:data, :loads, :edges).map { |edge| edge.dig(:node, :loadDate) }
  end

  describe "loads for another day" do
    it "makes a load for a day ahead, numbered within that day" do
      json = create_load(loadDate: (today + 3).iso8601)

      expect(json.dig(:data, :createLoad, :errors)).to be_nil
      expect(json.dig(:data, :createLoad, :load)).to include(loadDate: (today + 3).iso8601, loadNumber: 1)
      expect(json.dig(:data, :createLoad, :load, :loadNumber)).to eq(1)
      expect(create_load.dig(:data, :createLoad, :load, :loadNumber)).to eq(1)
    end

    it "makes a load for today when no day is given" do
      expect(create_load.dig(:data, :createLoad, :load, :loadDate)).to eq(today.iso8601)
    end

    it "refuses a day that has gone" do
      json = nil
      expect { json = create_load(loadDate: (today - 1).iso8601) }.not_to change(Load, :count)

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json.dig(:data, :createLoad, :fieldErrors, 0)).to include(field: "load_date", message: "cannot be a day that has gone")
    end

    it "lists the loads of a day, and of a range of days" do
      create_load
      create_load(loadDate: (today + 2).iso8601)
      create_load(loadDate: (today + 5).iso8601)

      expect(load_days(date: today.iso8601)).to eq([today.iso8601])
      expect(load_days(date: (today + 2).iso8601)).to eq([(today + 2).iso8601])
      expect(load_days(from: (today + 1).iso8601)).to eq([(today + 5).iso8601, (today + 2).iso8601])
      expect(load_days(to: (today + 2).iso8601)).to eq([(today + 2).iso8601, today.iso8601])
      expect(load_days(from: (today + 1).iso8601, to: (today + 3).iso8601)).to eq([(today + 2).iso8601])
    end

    it "lists every load without a day" do
      create_load
      create_load(loadDate: (today + 2).iso8601)

      expect(load_days.size).to eq(2)
    end
  end

  describe "when a load left and landed" do
    let!(:load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 8) }

    it "keeps neither while the load is open" do
      expect(load).to have_attributes(departed_at: nil, completed_at: nil)
    end

    it "keeps when it left" do
      freeze_time do
        load.depart!

        expect(load.reload).to have_attributes(departed_at: Time.current, completed_at: nil)
      end
    end

    it "keeps when it landed, and left when it landed straight away" do
      freeze_time do
        load.complete!

        expect(load.reload).to have_attributes(departed_at: Time.current, completed_at: Time.current)
      end
    end

    it "keeps when it left when it lands later" do
      left = 20.minutes.ago.change(usec: 0)
      travel_to(left) { load.depart! }

      load.complete!

      expect(load.reload.departed_at).to eq(left)
      expect(load.completed_at).to be > left
    end

    it "clears both when the load is reopened" do
      load.complete!

      load.reopen!

      expect(load.reload).to have_attributes(state: "open", departed_at: nil, completed_at: nil)
    end

    it "shows them over GraphQL" do
      load.complete!

      json = client_operation("Load", variables: { id: load.id }, as: owner_user)

      expect(json.dig(:data, :load, :completedAt)).to be_present
      expect(json.dig(:data, :load, :departedAt)).to be_present
    end
  end

  describe "prepaid slots" do
    let!(:load) { create(:load, vehicle: vehicle, pilot: pilot, gca: owner, load_master: owner, max_slots: 8) }
    let(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
    let(:tandem) { create(:ticket_type, operator: operator, name: "Tandem", cost: 250, requires_escort: true) }
    let(:jumper) { create(:membership, operator: operator, credits: 300) }
    let(:activity) { ActivityType.allowed_for([jumper]).first }

    def manifest(ticket_type, prepaid: nil, as: owner_user, guests: nil)
      attributes = { membership: jumper.id.to_s, ticketType: ticket_type.id.to_s, activityType: activity.id.to_s, load: load.id.to_s, bodyMassKg: 80 }
      attributes[:prepaid] = prepaid unless prepaid.nil?
      attributes[:guests] = guests if guests
      query = "mutation($attributes: SlotInput!) { createSlot(input: { attributes: $attributes }) { errors slot { id prepaid costCents } } }"
      post "/graphql", params: { query: query, variables: { attributes: attributes }.to_json }, headers: as.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "charges an ordinary ticket to the member" do
      json = nil
      expect { json = manifest(ticket) }.to change { jumper.reload.credits_cents }.by(-4000)

      expect(json.dig(:data, :createSlot, :slot, :prepaid)).to be(false)
      expect(Slot.find(json.dig(:data, :createSlot, :slot, :id)).order).to be_present
    end

    it "takes nothing for a ticket that requires an escort: the guest paid" do
      json = nil
      expect { json = manifest(tandem, guests: [{ name: "Pat", bodyMassKg: 70 }]) }.not_to(change { [jumper.reload.credits_cents, operator.reload.credits_cents] })

      slot = Slot.find(json.dig(:data, :createSlot, :slot, :id))
      expect(slot).to be_prepaid
      expect(slot.order).to be_nil
      expect(slot.guest_slots).to all(be_prepaid)
    end

    it "lets an escort fly without credits, which a prepaid slot does not need" do
      jumper.update!(credits: 0)

      expect(manifest(tandem, guests: [{ name: "Pat", bodyMassKg: 70 }]).dig(:data, :createSlot, :errors)).to be_nil
    end

    it "is not charged when the load lands, or refunded when the slot goes" do
      json = manifest(tandem, guests: [{ name: "Pat", bodyMassKg: 70 }])
      slot = Slot.find(json.dig(:data, :createSlot, :slot, :id))

      expect { load.reload.complete! }.not_to(change { jumper.reload.credits_cents })
      expect { Manifest::DeleteSlot.run!(access_context: ApplicationInteraction::AccessContext.new(owner), slot: slot.reload) }.not_to(change { jumper.reload.credits_cents })
    end

    it "needs createPrepaidSlot to say it either way" do
      stranger = create(:membership, operator: operator).tap { |member| member.grant!(:createUserSlot) }

      json = manifest(ticket, prepaid: true, as: stranger.user)

      expect(json.dig(:data, :createSlot, :errors).join).to match(/missing createPrepaidSlot/)
      expect(Slot.where(membership: jumper)).to be_empty
    end

    it "makes an ordinary ticket prepaid for someone who may" do
      owner.grant!(:createPrepaidSlot)

      expect { manifest(ticket, prepaid: true) }.not_to(change { jumper.reload.credits_cents })
      expect(Slot.find_by!(membership: jumper)).to be_prepaid
    end

    it "is given to the roles that create slots for others" do
      expect(Permission.slugs.map(&:to_s)).to include("createPrepaidSlot")
      expect(operator.user_roles.find_by(name: "manifest").permissions.pluck(:name)).to include("createPrepaidSlot")
      expect(operator.user_roles.find_by(name: "student").permissions.pluck(:name)).not_to include("createPrepaidSlot")
    end

    it "keeps a prepaid slot's credits out of the eligibility check" do
      jumper.update!(credits: 0)
      slot = Slot.new(load: load, membership: jumper, ticket_type: tandem, activity_type: activity, body_mass_kg: 80, prepaid: true)

      expect(Eligibility.check(Eligibility::Context.new(slot)).find { |result| result.code == "credits" }.status).to eq("NOT_REQUIRED")
    end
  end

  describe "how bookings reach the manifest" do
    it "is checkin for skydiving and load for the generic template" do
      expect(Industry.fetch("skydiving").booking).to eq("manifest_link" => "checkin")
      expect(Industry.fetch("generic").booking).to eq("manifest_link" => "load")
    end

    it "is exposed on the industry templates" do
      post "/graphql", params: { query: "{ industries { slug booking { manifestLink } } }" }, headers: owner_user.create_new_auth_token

      booking = response.parsed_body.dig("data", "industries").to_h { |industry| [industry["slug"], industry.dig("booking", "manifestLink")] }
      expect(booking).to include("SKYDIVING" => "CHECKIN", "GENERIC" => "LOAD")
    end

    it "refuses a link the schema does not know" do
      template = Industry.fetch("generic").template.merge("booking" => { "manifest_link" => "carrier_pigeon" })

      expect(Industry::SCHEMA.validate(template).to_a).not_to be_empty
    end
  end
end
