# frozen_string_literal: true

require "rails_helper"

RSpec.describe EquipmentInspection do
  let!(:certification_body) { CertificationBody.find_by(slug: :apf) }
  let!(:operator) { create(:operator) }
  let!(:memberships) { create_list(:membership, 5, operator: operator) }
  let!(:operator_equipment) { create_list(:equipment, 5, operator: operator, is_public: true) }

  before do
    inspector = create(:membership, operator: operator)
    # Create a few different equipment for each user
    memberships.each do |dz_user|
      create_list(:equipment, 3, user: dz_user.user)

      # Take 2 random equipment for each user and approve them
      chosen = dz_user.user.equipment.shuffle.take(2)
      chosen.each do |equipment|
        create(
          :equipment_inspection,
          is_ok: true,
          membership: dz_user,
          equipment: equipment,
          inspected_by: inspector,
        )
      end
    end
  end

  describe "Equipment.inspected_at" do
    it "returns the 2 approved equipment of each member" do
      memberships.each do |dzu|
        expect(dzu.user.equipment.inspected_at(operator).count).to eq 2
      end
    end
  end

  describe "Membership.available_equipment" do
    it "returns 2 approved equipment + 5 operator equipment" do
      memberships.each do |dzu|
        expect(dzu.operator.equipment.count).to eq 5
        expect(dzu.available_equipment.count).to eq 7
      end
    end
  end
end
