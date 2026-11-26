# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012150000_generalise_equipment")

# P7.14: rigs become equipment of the rig kind, the canopy size in m², the repack date the service date, the rig on a slot a
# row of slot_equipment, the inspection form of the operator the form of the kind. The example goes back to the old tables
# inside its transaction, writes old rows, migrates forward and reads the new ones.
RSpec.describe GeneraliseEquipment do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator, lat: nil, lng: nil) }
  let(:member) { create(:membership, operator: operator) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models
    [Equipment, EquipmentKind, EquipmentInspection, Slot, SlotEquipment, Operator, Pack].each(&:reset_column_information)
  end

  after { reset_models }

  def sql(statement) = connection.select_value(statement)

  # An operator with a rig of its own and a member's rig in the old tables
  def old_rigs
    form_id = operator.equipment_kinds.first.inspection_form_template_id
    operator.update_columns(industry: "skydiving")
    member
    quietly { described_class.new.migrate(:down) }
    reset_models
    connection.execute("UPDATE operators SET rig_inspection_template_id = #{form_id} WHERE id = #{operator.id}")
    connection.execute(<<~SQL.squish)
      INSERT INTO rigs (operator_id, user_id, make, model, serial, rig_type, canopy_size, pack_value, repack_expires_at, is_public, created_at, updated_at)
      VALUES (#{operator.id}, NULL, 'Vector', 'V310', '1', 0, 190, 12, '2027-01-01 00:00:00', TRUE, NOW(), NOW()),
             (NULL, #{member.user_id}, 'Javelin', 'J3', '2', 2, NULL, NULL, NULL, FALSE, NOW(), NOW())
    SQL
    connection.execute("UPDATE operators SET settings = settings || '{\"require_rig_inspection\": false, \"require_reserve_in_date\": true}'::jsonb WHERE id = #{operator.id}")
    form_id
  end

  it "goes back to rigs with their columns" do
    quietly { described_class.new.migrate(:down) }
    reset_models

    expect(connection.table_exists?(:rigs)).to be true
    expect(connection.table_exists?(:equipment)).to be false
    expect(connection.column_exists?(:rigs, :repack_expires_at)).to be true
    expect(connection.column_exists?(:slots, :rig_id)).to be true
  end

  it "makes a rig of the operator and a rig of the member equipment of the rig kind, with properties" do
    form_id = old_rigs

    quietly { described_class.new.migrate(:up) }
    reset_models

    kind = EquipmentKind.find_by!(operator_id: operator.id, key: "rig")
    expect(kind.inspection_form_template_id).to eq(form_id)
    rented, own = Equipment.order(:id).to_a
    expect(rented).to have_attributes(kind_id: kind.id, ownership: "operator", service_due_at: Time.utc(2027, 1, 1), is_public: true)
    expect(rented.properties).to eq("rig_type" => "student", "canopy_size_m2" => (190 * 0.09290304).round(4), "pack_value" => 12)
    expect(own).to have_attributes(kind_id: kind.id, ownership: "personal", user_id: member.user_id, service_due_at: nil)
    expect(own.properties).to eq("rig_type" => "tandem")
  end

  it "keeps the rig of a slot as a row of slot_equipment" do
    old_rigs
    vehicle_load = create(:load, vehicle: create(:vehicle, operator: operator), gca: member, pilot: member)
    rig_id = sql("SELECT id FROM rigs ORDER BY id LIMIT 1")
    connection.execute(<<~SQL.squish)
      INSERT INTO slots (load_id, membership_id, rig_id, ticket_type_id, group_number, body_mass_kg, created_at, updated_at)
      VALUES (#{vehicle_load.id}, #{member.id}, #{rig_id}, #{create(:ticket_type, operator: operator).id}, 1, 80, NOW(), NOW())
    SQL

    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(sql("SELECT COUNT(*) FROM slot_equipment")).to eq(1)
    expect(sql("SELECT equipment_id FROM slot_equipment")).to eq(rig_id)
    expect(Slot.column_names).not_to include("rig_id")
  end

  it "renames the settings of the operator and the class names stored for events" do
    old_rigs
    connection.execute("INSERT INTO events (operator_id, resource_type, resource_id, action, level, access_level, message, created_at, updated_at) " \
                       "VALUES (#{operator.id}, 'Rig', 1, 0, 0, 0, 'x', NOW(), NOW())")

    quietly { described_class.new.migrate(:up) }
    reset_models

    expect(operator.reload.settings).to include("require_equipment_inspection" => false, "require_equipment_in_service" => true)
    expect(operator.settings).not_to include("require_rig_inspection", "require_reserve_in_date")
    expect(sql("SELECT resource_type FROM events WHERE message = 'x'")).to eq("Equipment")
  end
end
