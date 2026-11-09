# frozen_string_literal: true

require "rails_helper"

# UB.2: staff with updateUser run a member's personal equipment from the office; nobody else touches them
RSpec.describe "Office equipment management" do
  let(:operator) { create(:operator, state: "public") }
  let(:other_operator) { create(:operator, state: "public") }

  let(:staff_user) { create(:user) }
  let!(:staff) { create(:membership, operator: operator, user: staff_user, user_role: operator.user_roles.find_by(name: "manifest")) }
  let(:member_user) { create(:user) }
  let!(:member) { create(:membership, operator: operator, user: member_user, user_role: operator.user_roles.find_by(name: "fun_jumper")) }
  let(:jumper_user) { create(:user) }
  let!(:jumper) { create(:membership, operator: operator, user: jumper_user, user_role: operator.user_roles.find_by(name: "fun_jumper")) }
  let(:foreign_staff_user) { create(:user) }
  let!(:foreign_staff) do
    create(:membership, operator: other_operator, user: foreign_staff_user, user_role: other_operator.user_roles.find_by(name: "owner"))
  end
  let!(:equipment) { create(:equipment, user: member_user, operator: nil, name: "Original", service_due_at: 3.months.from_now) }

  def create_equipment(as:, user: member_user)
    client_operation("CreateEquipment", variables: {
      name: "Office equipment", make: "Aerodyne", model: "Smart", serial: "S-1", equipmentType: "tandem",
      canopySize: 190, userId: user.id, serviceDueAt: 3.months.from_now.to_i,
    }, as: as)
  end

  def update_equipment(as:, target: equipment)
    client_operation("UpdateEquipment", variables: { id: target.id, name: "Renamed" }, as: as)
  end

  def archive_equipment(as:, target: equipment)
    client_operation("ArchiveEquipment", variables: { id: target.id }, as: as)
  end

  it "has the staff role holding updateUser and the jumper role not" do
    expect(staff.can?(:updateUser)).to be(true)
    expect(jumper.can?(:updateUser)).to be(false)
    expect(foreign_staff.can?(:updateUser)).to be(true)
  end

  describe "staff of the member's operator" do
    it "creates a equipment for the member" do
      json = create_equipment(as: staff_user)

      expect(json.dig(:data, :createEquipment, :errors)).to be_blank
      expect(member_user.equipment.reload.pluck(:name)).to include("Office equipment")
    end

    it "updates the member's equipment" do
      expect(update_equipment(as: staff_user).dig(:data, :updateEquipment, :errors)).to be_blank
      expect(equipment.reload.name).to eq("Renamed")
    end

    it "archives the member's equipment" do
      expect(archive_equipment(as: staff_user).dig(:data, :archiveEquipment, :errors)).to be_blank
      expect(equipment.reload).to be_discarded
    end
  end

  describe "everybody else" do
    it "refuses staff of another operator" do
      create_equipment(as: foreign_staff_user)
      update_equipment(as: foreign_staff_user)
      archive_equipment(as: foreign_staff_user)

      expect(member_user.equipment.reload.pluck(:name)).to eq(["Original"])
      expect(equipment.reload).to have_attributes(name: "Original", discarded_at: nil)
    end

    it "refuses a fun jumper touching another member's equipment" do
      expect(create_equipment(as: jumper_user).dig(:data, :createEquipment, :equipment)).to be_nil
      expect(update_equipment(as: jumper_user).dig(:data, :updateEquipment, :equipment)).to be_nil
      expect(archive_equipment(as: jumper_user).dig(:data, :archiveEquipment, :equipment)).to be_nil

      expect(member_user.equipment.reload.pluck(:name)).to eq(["Original"])
      expect(equipment.reload).to have_attributes(name: "Original", discarded_at: nil)
    end

    it "refuses staff when the equipment's owner is not a member of their operator" do
      stranger = create(:user)
      stranger_equipment = create(:equipment, user: stranger, operator: nil, name: "Stranger")

      expect(create_equipment(as: staff_user, user: stranger).dig(:data, :createEquipment, :equipment)).to be_nil
      expect(update_equipment(as: staff_user, target: stranger_equipment).dig(:data, :updateEquipment, :equipment)).to be_nil
      expect(archive_equipment(as: staff_user, target: stranger_equipment).dig(:data, :archiveEquipment, :equipment)).to be_nil
      expect(stranger_equipment.reload).to have_attributes(name: "Stranger", discarded_at: nil)
    end
  end

  it "still lets members manage their own equipment" do
    expect(update_equipment(as: member_user).dig(:data, :updateEquipment, :errors)).to be_blank
    expect(equipment.reload.name).to eq("Renamed")
    expect(archive_equipment(as: member_user).dig(:data, :archiveEquipment, :errors)).to be_blank
    expect(equipment.reload).to be_discarded
  end
end
