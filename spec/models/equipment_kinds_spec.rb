# frozen_string_literal: true

require "rails_helper"

# P7.14: equipment of operator-defined kinds with validated attributes, service dates and inspections that stay valid for
# a number of days; a slot can use several items; skydiving's rig is a kind with its own helpers
RSpec.describe "Equipment kinds" do
  let(:operator) { create(:operator) }
  let(:rig_kind) { operator.equipment_kinds.find_by!(key: "rig") }
  let(:owner) { create(:membership, operator: operator) }
  let(:inspector) { create(:membership, operator: operator) }
  let(:template) { create(:form_template, operator: operator) }

  def kind(attrs = {})
    operator.equipment_kinds.create!({ key: "wetsuit", name: "Wetsuit", attribute_schema: {} }.merge(attrs))
  end

  def item(kind, props = {}, **attrs)
    Equipment.new({ kind: kind, operator: operator, properties: props }.merge(attrs))
  end

  describe EquipmentKind do
    it "comes with the operator's template: the skydiving rig, with its form" do
      expect(rig_kind).to have_attributes(name: "Rig", service_interval_days: 180, inspection_valid_days: nil)
      expect(rig_kind.attribute_schema.keys).to match_array(%w(rig_type canopy_size_m2 pack_value))
      expect(rig_kind.inspection_form_template).to be_present
      expect(rig_kind.required_by).to eq("always" => true)
    end

    it "keeps a key once per operator" do
      expect(operator.equipment_kinds.new(key: "rig", name: "Again")).not_to be_valid
      expect(create(:operator).equipment_kinds.find_by(key: "rig")).to be_present
    end

    it "needs a known type for each attribute, and the choices of an enum" do
      bad = operator.equipment_kinds.new(key: "pfd", name: "PFD", attribute_schema: { "size" => { "type" => "bogus" }, "colour" => { "type" => "enum" } })

      expect(bad).not_to be_valid
      expect(bad.errors[:attribute_schema].join).to include("size has an unknown type", "colour needs the values")
    end

    it "is required by every slot, by listed ticket types or activity types, or by none" do
      expect(rig_kind.required_for?).to be true
      listed = kind(required_by: { "ticket_type_ids" => [4], "activity_type_ids" => [9] })

      expect(listed.required_for?(ticket_type_id: 4)).to be true
      expect(listed.required_for?(activity_type_id: 9)).to be true
      expect(listed.required_for?(ticket_type_id: 5, activity_type_id: 8)).to be false
      expect(kind(key: "none").required_for?(ticket_type_id: 4)).to be false
    end

    it "keeps an inspection valid for the days of the kind, indefinitely without them" do
      daily = kind(key: "glider", inspection_valid_days: 1)

      expect(daily.inspection_valid?(2.hours.ago)).to be true
      expect(daily.inspection_valid?(2.days.ago)).to be false
      expect(rig_kind.inspection_valid?(5.years.ago)).to be true
    end
  end

  describe "attributes" do
    let(:suit) do
      kind(attribute_schema: {
        "size" => { "type" => "enum", "values" => %w(S M L), "required" => true },
        "thickness_mm" => { "type" => "integer", "min" => 1, "max" => 9 },
        "length_m" => { "type" => "decimal", "default" => 1.5 },
        "bought_on" => { "type" => "date" },
        "colour" => { "type" => "string" },
      })
    end

    it "keeps values the schema accepts, coerced, with the defaults" do
      equipment = item(suit, { "size" => "M", "thickness_mm" => "5", "bought_on" => "2026-03-04", "colour" => "blue" })

      expect(equipment).to be_valid
      expect(equipment.properties).to eq("size" => "M", "thickness_mm" => 5, "length_m" => 1.5, "bought_on" => "2026-03-04", "colour" => "blue")
    end

    it "refuses what it does not accept" do
      equipment = item(suit, { "size" => "XL", "thickness_mm" => 12, "bought_on" => "yesterday", "hood" => true })

      expect(equipment).not_to be_valid
      expect(equipment.errors[:properties]).to include(
        "size must be one of S, M, L", "thickness_mm must be at most 9", "bought_on is not a valid date", "hood is not an attribute of Wetsuit"
      )
    end

    it "needs an attribute that is required" do
      equipment = item(suit, {})

      expect(equipment).not_to be_valid
      expect(equipment.errors[:properties]).to include("size is required")
    end

    it "validates the skydiving rig: its type, canopy size in m² and pack value" do
      rig = item(rig_kind, { "rig_type" => "student", "canopy_size_m2" => 17.65, "pack_value" => 10 })
      expect(rig).to be_valid

      bad = item(rig_kind, { "rig_type" => "hang glider", "canopy_size_m2" => -1 })
      expect(bad).not_to be_valid
      expect(bad.errors[:properties].join).to include("rig_type must be one of", "canopy_size_m2 must be at least 0")
    end

    it "defaults a rig to a sport rig" do
      expect(item(rig_kind, {}).tap(&:valid?).properties).to eq("rig_type" => "sport")
    end
  end

  describe "ownership and kind" do
    it "belongs to the operator when it has one, else to the member" do
      expect(item(rig_kind).tap(&:valid?)).to be_ownership_operator
      expect(item(rig_kind, {}, operator: nil, user: owner.user).tap(&:valid?)).to be_ownership_personal
    end

    it "needs an owner" do
      expect(item(rig_kind, {}, operator: nil, user: nil)).not_to be_valid
    end

    it "cannot be of the kind of another operator" do
      expect(item(create(:operator).equipment_kinds.first)).not_to be_valid
    end

    it "needs a kind" do
      expect(Equipment.new(operator: operator)).not_to be_valid
    end
  end

  describe "service" do
    it "is in service until the date of a serviced kind; a kind that is not serviced is always in service" do
      rig = item(rig_kind, {}, service_due_at: 1.month.from_now)
      expired = item(rig_kind, {}, service_due_at: 1.day.ago)
      undated = item(rig_kind, {}, service_due_at: nil)
      pfd = item(kind(key: "pfd", name: "PFD"), {}, service_due_at: nil)

      expect([rig, expired, undated, pfd].map(&:in_service?)).to eq([true, false, false, true])
    end

    it "filters by service date" do
      rig = create(:equipment, operator: operator, service_due_at: 1.month.from_now)
      create(:equipment, operator: operator, service_due_at: 1.day.ago)

      expect(operator.equipment.in_service).to eq([rig])
    end

    it "records a service: it is next due after the kind's interval" do
      rig = create(:equipment, operator: operator, service_due_at: 1.day.ago)

      rig.record_service(at: Time.zone.parse("2026-01-01 00:00"))

      expect(rig.reload.service_due_at).to eq(Time.zone.parse("2026-01-01 00:00") + 180.days)
      expect(rig.maintained_at).to eq(Time.zone.parse("2026-01-01 00:00"))
    end
  end

  describe "rental" do
    it "rents out public items of the operator, but not tandem rigs" do
      expect(item(rig_kind, { "rig_type" => "student" }, is_public: true)).to be_rentable
      expect(item(rig_kind, { "rig_type" => "tandem" }, is_public: true)).not_to be_rentable
      expect(item(rig_kind, { "rig_type" => "student" }, is_public: false)).not_to be_rentable
      expect(item(rig_kind, {}, operator: nil, user: owner.user, is_public: true)).not_to be_rentable
    end
  end

  describe "inspections" do
    let(:glider) { kind(key: "glider", name: "Glider", inspection_valid_days: 1, inspection_form_template: template) }
    let(:aircraft) { Equipment.create!(kind: glider, operator: operator, properties: {}) }

    def inspect!(equipment, at:, is_ok: true)
      EquipmentInspection.create!(equipment: equipment, membership: owner, inspected_by: inspector, form_template: template, is_ok: is_ok, definition: "[]").tap do |inspection|
        inspection.update_columns(updated_at: at)
      end
    end

    it "stays valid for one day for a kind with a one-day validity" do
      inspect!(aircraft, at: 3.hours.ago)
      expect(operator.equipment.inspected_at(operator)).to include(aircraft)
      expect(aircraft).to be_inspected_at(operator)

      EquipmentInspection.update_all(updated_at: 2.days.ago)

      expect(operator.equipment.inspected_at(operator)).not_to include(aircraft)
      expect(operator.equipment.not_inspected_at(operator)).to include(aircraft)
      expect(aircraft).not_to be_inspected_at(operator)
    end

    it "stays valid for good for a kind without a validity (a rig)" do
      rig = create(:equipment, operator: operator)
      inspect!(rig, at: 3.years.ago)

      expect(operator.equipment.inspected_at(operator)).to include(rig)
    end

    it "does not count a failed inspection" do
      inspect!(aircraft, at: 1.hour.ago, is_ok: false)

      expect(operator.equipment.inspected_at(operator)).not_to include(aircraft)
    end

    it "starts again when the item is inspected again" do
      rig = create(:equipment, user: owner.user, operator: nil)
      ac = ApplicationInteraction::AccessContext.new(inspector.tap { |staff| staff.grant!(:actAsEquipmentInspector) })
      inspect!(rig, at: 3.days.ago)
      daily = rig.kind.tap { |k| k.update!(inspection_valid_days: 1) }
      expect(daily.inspection_valid?(EquipmentInspection.last.updated_at)).to be false

      Setup::Equipment::CreateEquipmentInspection.run!(access_context: ac, equipment: rig, operator: operator, definition: "[]", is_ok: true)

      expect(EquipmentInspection.where(equipment: rig).count).to eq(1)
      expect(EquipmentInspection.last).to be_current
    end
  end

  describe "slots" do
    let(:vehicle) { create(:vehicle, operator: operator) }
    let(:vehicle_load) { create(:load, vehicle: vehicle, gca: create(:membership, operator: operator), pilot: create(:membership, operator: operator)) }
    let(:member) { create(:membership, operator: operator, credits: 500) }
    let(:ticket_type) { create(:ticket_type, operator: operator) }
    let(:buoyancy) { kind(key: "bcd", name: "BCD") }
    let(:regulator) { kind(key: "regulator", name: "Regulator") }

    def slot_with(items)
      Slot.new(load: vehicle_load, membership: member, ticket_type: ticket_type, activity_type: ActivityType.find_by!(slug: "fs"), equipment: items, body_mass_kg: 80)
    end

    it "uses several items: a diver's BCD and regulator" do
      bcd = Equipment.create!(kind: buoyancy, operator: operator, properties: {})
      reg = Equipment.create!(kind: regulator, operator: operator, properties: {})
      slot = slot_with([bcd, reg])
      slot.save!(validate: false)

      expect(slot.reload.equipment).to contain_exactly(bcd, reg)
      expect(bcd.reload.slots).to eq([slot])
      expect(SlotEquipment.where(slot: slot).count).to eq(2)
    end

    it "takes the member's own items and the operator's, not somebody else's" do
      own = create(:equipment, user: member.user, operator: nil)
      operators = create(:equipment, operator: operator)
      foreign = create(:equipment, user: create(:user), operator: nil)
      other_operator = create(:equipment, operator: create(:operator))

      expect(slot_with([own, operators])).to be_valid
      expect(slot_with([foreign]).tap(&:valid?).errors[:equipment]).to be_present
      expect(slot_with([other_operator]).tap(&:valid?).errors[:equipment]).to be_present
    end

    it "lists an item once on a slot" do
      rig = create(:equipment, operator: operator)
      slot = slot_with([rig])
      slot.save!(validate: false)

      expect { SlotEquipment.create!(slot: slot, equipment: rig) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "marks equipment as occupied while its load has not completed" do
      rig = create(:equipment, operator: operator)
      slot_with([rig]).save!(validate: false)

      expect(Equipment.occupied).to include(rig)
    end

    it "gives the wing loading of the slot's rig in pounds per square foot, with a tandem passenger's weight" do
      rig = create(:equipment, operator: operator, canopy_size_ft2: 100)
      slot = slot_with([rig])

      expect(slot.wing_loading).to be_within(0.01).of(80 * 2.2046226 / 100)
      expect(slot_with([]).wing_loading).to be_nil
      expect(slot_with([Equipment.create!(kind: buoyancy, operator: operator, properties: {})]).wing_loading).to be_nil
    end
  end

  describe Skydiving::Rigs do
    it "finds the student and tandem rigs of an operator" do
      student = create(:equipment, operator: operator, rig_type: "student")
      tandem = create(:equipment, operator: operator, rig_type: "tandem")
      create(:equipment, operator: operator, rig_type: "sport")
      create(:equipment, operator: create(:operator), rig_type: "student")

      expect(described_class.student(operator)).to eq([student])
      expect(described_class.tandem(operator)).to eq([tandem])
    end

    it "calculates the wing loading, and none without a canopy or a weight" do
      rig = item(rig_kind, { "canopy_size_m2" => 9.290304 })

      expect(described_class.wing_loading(rig, 45.359237)).to be_within(0.0001).of(1.0)
      expect(described_class.wing_loading(rig, nil)).to be_nil
      expect(described_class.wing_loading(item(rig_kind, {}), 80)).to be_nil
      expect(described_class.wing_loading(nil, 80)).to be_nil
    end
  end

  describe "available equipment" do
    it "offers the rentable items of the operator for a kind, in service, to a member" do
      member = create(:membership, operator: operator)
      student = create(:equipment, operator: operator, rig_type: "student", is_public: true)
      create(:equipment, operator: operator, rig_type: "tandem", is_public: true)
      create(:equipment, operator: operator, rig_type: "student", is_public: true, service_due_at: 1.day.ago)
      pfd = Equipment.create!(kind: kind(key: "pfd", name: "PFD"), operator: operator, properties: {}, is_public: true)

      expect(member.available_equipment(kind: "rig")).to contain_exactly(student)
      expect(member.available_equipment(kind: "pfd")).to contain_exactly(pfd)
      expect(member.available_equipment).to contain_exactly(student, pfd)
    end
  end
end
