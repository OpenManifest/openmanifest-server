# frozen_string_literal: true

require "rails_helper"

# P7.16: every rule of Eligibility on its own, the modules that switch them on and off, and the member's side of it
RSpec.describe Eligibility do
  let(:operator) { create(:operator, credits: 50) }
  let(:vehicle) { create(:vehicle, operator: operator, capacity: 6) }
  let(:gca) { create(:membership, operator: operator) }
  let(:pilot) { create(:membership, operator: operator) }
  let(:vehicle_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }
  let(:user) { create(:user, body_mass_kg: 80, date_of_birth: Date.new(1990, 1, 1)) }
  let(:membership) { create(:membership, operator: operator, user: user, credits: 500) }
  let(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
  let(:activity) { ActivityType.allowed_for([membership]).first }

  def slot_for(member = membership, load: vehicle_load, ticket_type: ticket, body_mass_kg: 80, **attributes)
    Slot.new(load: load, membership: member, ticket_type: ticket_type, activity_type: activity, body_mass_kg: body_mass_kg, **attributes)
  end

  # A slot of somebody else on the load, saved
  def other_slot(**attributes)
    member = create(:membership, operator: operator, credits: 500)
    create(:slot, load: vehicle_load, membership: member, operator: operator, activity_type: ActivityType.allowed_for([member]).first, **attributes)
  end

  def results(slot, scopes: %i(slot))
    described_class.check(Eligibility::Context.new(slot), scopes: scopes).index_by(&:code)
  end

  def failure_messages(slot)
    slot.valid?
    slot.errors.full_messages
  end

  describe "a slot that is fine" do
    it "passes every rule that applies, and is valid" do
      slot = slot_for

      expect(results(slot).values).to all(be_ok)
      expect(slot).to be_valid
    end
  end

  describe "capacity" do
    it "fails when the load has no seat left" do
      vehicle_load.update_columns(max_slots: 0)

      expect(results(slot_for)["capacity"]).to have_attributes(ok: false, message: "No slots available on this load")
    end

    it "needs a seat for the slot and for each guest" do
      vehicle_load.update_columns(max_slots: 1)
      escort_ticket = create(:ticket_type, operator: operator, name: "Tandem", requires_escort: true)
      slot = slot_for(ticket_type: escort_ticket)
      slot.guest_slots.build(load: vehicle_load, ticket_type: escort_ticket, guest: Guest.new(operator: operator, name: "Pat"), body_mass_kg: 70)

      expect(results(slot)["capacity"]).not_to be_ok
    end

    it "fails when the chosen vehicle has no seat left" do
      row = vehicle_load.load_vehicles.first
      row.update_columns(slots_count: row.capacity)

      expect(results(slot_for(load_vehicle: row))["capacity"]).to have_attributes(ok: false, problem: "vehicle_capacity")
    end
  end

  describe "membership" do
    it "fails for a membership that has run out, with the member's name" do
      membership.update!(expires_at: 1.day.ago)

      expect(results(slot_for)["membership"]).to have_attributes(ok: false, message: "#{user.name}'s membership has expired")
    end

    it "is not required when the operator does not ask for it" do
      membership.update!(expires_at: 1.day.ago)
      operator.update!(settings: operator.settings.merge("require_membership" => false))

      expect(results(slot_for)["membership"].status).to eq("NOT_REQUIRED")
    end

    it "can be let through by a manifester who may bypass, when the operator allows it" do
      membership.update!(expires_at: 1.day.ago)
      operator.update!(settings: operator.settings.merge("allow_manifest_bypass" => true))
      manifester = create(:membership, operator: operator).tap { |member| member.grant!(:createUserSlot) }

      result = results(slot_for(created_by: manifester))["membership"]

      expect(result).to have_attributes(ok: false, bypassed: true)
      expect(slot_for(created_by: manifester)).to be_valid
    end
  end

  describe "credits" do
    it "fails when the ticket costs more than the member has" do
      membership.update!(credits: 1)

      expect(results(slot_for)["credits"]).to have_attributes(ok: false, message: "Not enough credits to manifest for this jump")
    end

    it "is not required when credits may go negative" do
      membership.update!(credits: 1)
      operator.update!(settings: operator.settings.merge("allow_negative_credits" => true))

      expect(results(slot_for)["credits"].status).to eq("NOT_REQUIRED")
    end
  end

  describe "double manifesting" do
    it "fails for a member who is on another load of the day" do
      other_load = create(:load, vehicle: vehicle, gca: gca, pilot: pilot)
      create(:slot, load: other_load, membership: membership, operator: operator, activity_type: activity)

      expect(results(slot_for)["double_manifest"]).to have_attributes(ok: false, message: "Double-manifesting is not allowed")
    end
  end

  describe "modules" do
    it "leaves out the rules of a module that is off" do
      operator.update!(modules: { limits: false, certifications: false, escorts: false })

      expect(results(slot_for, scopes: %i(slot manifest)).keys).not_to include("age", "body_mass", "payload", "certification", "escort")
    end

    it "has them for the skydiving operator" do
      expect(results(slot_for, scopes: %i(slot manifest)).keys).to include("capacity", "membership", "credits", "age", "body_mass", "certification")
    end
  end

  describe "age" do
    let(:ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 40, participant_limits: { "min_age" => 18, "max_age" => 70 }) }

    it "passes at the minimum age on the day of the load" do
      user.update!(date_of_birth: vehicle_load.load_date - 18.years)

      expect(results(slot_for)["age"]).to be_ok
    end

    it "fails a day short of it" do
      user.update!(date_of_birth: vehicle_load.load_date - 18.years + 1.day)

      expect(results(slot_for)["age"]).to have_attributes(ok: false, problem: "age", message: "#{user.name} must be at least 18 years old")
    end

    it "fails above the maximum age" do
      user.update!(date_of_birth: vehicle_load.load_date - 71.years)

      expect(results(slot_for)["age"].message).to match(/at most 70/)
    end

    it "fails with its own problem when there is no date of birth" do
      user.update!(date_of_birth: nil)

      expect(results(slot_for)["age"]).to have_attributes(ok: false, problem: "date_of_birth_missing")
    end

    it "looks at the guests of an escort too" do
      ticket.update!(requires_escort: true, escort_capacity: 2)
      slot = slot_for
      slot.guest_slots.build(load: vehicle_load, ticket_type: ticket, body_mass_kg: 60, guest: Guest.new(operator: operator, name: "Kid", date_of_birth: vehicle_load.load_date - 10.years))

      expect(results(slot)["age"].message).to eq("Kid must be at least 18 years old")
    end

    it "takes the stricter of the ticket's limits and the activity's" do
      activity.update!(participant_limits: { "min_age" => 21 })
      user.update!(date_of_birth: vehicle_load.load_date - 19.years)

      expect(results(slot_for)["age"].message).to match(/at least 21/)
    ensure
      activity.update!(participant_limits: {})
    end

    it "asks nothing of a ticket without an age limit" do
      ticket.update!(participant_limits: {})
      user.update!(date_of_birth: nil)

      expect(results(slot_for)["age"]).to be_ok
    end
  end

  describe "body mass" do
    let(:ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 40, participant_limits: { "min_body_mass_kg" => 40, "max_body_mass_kg" => 100 }) }

    it "passes between the limits" do
      expect(results(slot_for(body_mass_kg: 70))["body_mass"]).to be_ok
    end

    it "fails above the maximum and below the minimum" do
      expect(results(slot_for(body_mass_kg: 101))["body_mass"].message).to match(/must weigh at most 100 kg/)
      expect(results(slot_for(body_mass_kg: 39))["body_mass"].message).to match(/must weigh at least 40 kg/)
    end

    it "fails with its own problem when there is no body mass" do
      user.update!(body_mass_kg: nil)

      expect(results(slot_for(body_mass_kg: nil))["body_mass"]).to have_attributes(ok: false, problem: "body_mass_missing")
    end
  end

  describe "flight groups" do
    let(:ticket) { create(:ticket_type, operator: operator, name: "Flight", cost: 40, group_limits: { "max_group_size" => 2, "max_group_body_mass_kg" => 200 }) }

    def in_group(number, mass: 70)
      other_slot(ticket_type: ticket, group_number: number, body_mass_kg: mass)
    end

    it "fails when the group would be bigger than the ticket allows" do
      in_group(1)
      in_group(1)

      expect(results(slot_for(group_number: 1))["group"]).to have_attributes(ok: false, problem: "group_size")
    end

    it "fails when the group would weigh more than the ticket allows" do
      in_group(1, mass: 130)

      expect(results(slot_for(group_number: 1, body_mass_kg: 80))["group"]).to have_attributes(ok: false, problem: "group_mass")
    end

    it "does not mix groups, and asks nothing of a slot without a group" do
      in_group(1)
      in_group(1)

      expect(results(slot_for(group_number: 2))["group"]).to be_ok
      expect(results(slot_for(group_number: 0))).not_to have_key("group")
    end
  end

  describe "payload" do
    it "fails when the load would be heavier than its vehicles can carry" do
      vehicle.update!(max_payload_kg: 200)
      pilot.user.update!(body_mass_kg: 60)
      vehicle_load.reload
      other_slot(body_mass_kg: 110)

      expect(results(slot_for(body_mass_kg: 100))["payload"]).to have_attributes(ok: false, problem: "load_payload")
    end

    it "counts the crew that rides, not the GCA on the ground" do
      vehicle.update!(max_payload_kg: 150)
      vehicle_load.reload
      pilot.user.update!(body_mass_kg: 90)
      gca.user.update!(body_mass_kg: 90)

      expect(results(slot_for(body_mass_kg: 70))["payload"]).not_to be_ok
      expect(results(slot_for(body_mass_kg: 50))["payload"]).to be_ok
    end

    it "asks nothing of vehicles that have no limit" do
      expect(results(slot_for(body_mass_kg: 5000))).not_to have_key("payload")
    end

    it "is checked again when a slot is changed" do
      vehicle.update!(max_payload_kg: 200)
      vehicle_load.reload
      slot = create(:slot, load: vehicle_load, membership: membership, operator: operator, activity_type: activity, body_mass_kg: 80)

      expect(slot.update(body_mass_kg: 250)).to be(false)
      expect(slot.errors.full_messages.join).to match(/can carry at most 200 kg/)
    end
  end

  describe "equipment, chosen with the slot" do
    let(:rig_kind) { operator.equipment_kinds.find_by!(key: "rig") }

    before { operator.update!(settings: operator.settings.merge("require_equipment" => true)) }

    def codes_of(slot) = results(slot, scopes: %i(manifest))

    it "needs an item of each kind the slot needs" do
      expect(codes_of(slot_for)["equipment"]).to have_attributes(ok: false, problem: "equipment_missing")
    end

    it "wants the member's own item inspected" do
      rig = create(:equipment, user: user, operator: nil, kind: rig_kind)
      slot = slot_for
      slot.equipment = [rig]

      expect(codes_of(slot)["equipment"]).to be_ok
      expect(codes_of(slot)["equipment_inspection"]).to have_attributes(ok: false, problem: "equipment_not_inspected")

      create(:equipment_inspection, is_ok: true, equipment: rig, membership: membership, inspected_by: gca)

      expect(codes_of(slot)["equipment_inspection"]).to be_ok
    end

    it "asks no inspection of the operator's own item" do
      rental = create(:equipment, operator: operator, user: nil, is_public: true, rig_type: "student")
      slot = slot_for
      slot.equipment = [rental]

      expect(codes_of(slot)["equipment_inspection"]).to be_ok
    end

    it "fails an item that is due for service" do
      rental = create(:equipment, operator: operator, user: nil, is_public: true, rig_type: "student", service_due_at: 1.day.ago)
      slot = slot_for
      slot.equipment = [rental]

      expect(codes_of(slot)["equipment_service"]).to have_attributes(ok: false, problem: "equipment_overdue")
    end

    it "is not asked of the slot itself, which stays valid" do
      expect(slot_for).to be_valid
    end

    it "stops CreateSlot when nothing is chosen" do
      outcome = Manifest::CreateSlot.run(access_context: access_context_for(operator), ticket_type: ticket, membership: membership, activity_type: activity,
                                         load: vehicle_load, body_mass_kg: 80)

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to match(/Needs rig to manifest/)
    end
  end

  describe "the member's side" do
    it "is ready when every rule that applies passes" do
      summary = described_class.summary(membership)

      expect(summary[:rules].map(&:code)).to include("membership", "credits", "certification", "body_mass")
      expect(summary[:ready]).to be(summary[:rules].none?(&:failed?))
    end

    it "is not ready without an exit weight, with its own problem" do
      user.update!(body_mass_kg: nil)
      summary = described_class.summary(membership)

      expect(summary[:ready]).to be(false)
      expect(summary[:rules].find { |rule| rule.code == "body_mass" }).to have_attributes(ok: false, problem: "body_mass_missing")
    end

    it "marks a membership that ends within 14 days as expiring" do
      membership.update!(expires_at: 5.days.from_now)

      expect(described_class.summary(membership)[:rules].find { |rule| rule.code == "membership" }).to have_attributes(ok: true, status: "EXPIRING")
    end

    it "carries the credits of the member" do
      expect(described_class.summary(membership)[:rules].find { |rule| rule.code == "credits" }.amount_cents).to eq(membership.credits_cents)
    end

    it "asks for a date of birth only when a ticket or an activity has an age limit" do
      user.update!(date_of_birth: nil)

      expect(described_class.summary(membership)[:rules].find { |rule| rule.code == "age" }.status).to eq("NOT_REQUIRED")

      create(:ticket_type, operator: operator, name: "Tandem", participant_limits: { "min_age" => 18 })

      expect(described_class.summary(Membership.find(membership.id))[:rules].find { |rule| rule.code == "age" }).to have_attributes(ok: false, problem: "date_of_birth_missing")
    end

    it "agrees with creating a slot on membership and credits" do
      membership.update!(expires_at: 1.day.ago, credits: 0)
      summary = described_class.summary(membership)
      failed = summary[:rules].select(&:failed?).map(&:code)

      expect(failed).to include("membership", "credits")
      expect(results(slot_for).select { |_code, result| result.failed? }.keys).to include("membership", "credits")
    end

    it "reads the equipment from the member's inspections" do
      operator.update!(settings: operator.settings.merge("require_equipment_inspection" => true))
      rig = create(:equipment, user: user, operator: nil)
      create(:equipment_inspection, is_ok: true, equipment: rig, membership: membership, inspected_by: gca)
      rules = described_class.summary(Membership.find(membership.id))[:rules].index_by(&:code)

      expect(rules["equipment_inspection"]).to be_ok
      expect(rules["equipment_service"]).to be_ok
    end
  end

  def access_context_for(operator)
    manifester = create(:membership, operator: operator)
    manifester.grant! :createSlot
    manifester.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(manifester)
  end
end
