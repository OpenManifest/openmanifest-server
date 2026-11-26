# frozen_string_literal: true

require "rails_helper"

RSpec.describe Equipment do
  describe ".not_inspected_at" do
    let(:operator) { create(:operator) }
    let(:owner) { create(:membership, operator: operator) }
    let(:inspector) { create(:membership, operator: operator) }
    let(:template) { create(:form_template, operator: operator) }
    let!(:never_inspected) { create(:equipment, user: owner.user, operator: nil) }
    let!(:cleared) { create(:equipment, user: owner.user, operator: nil) }
    let!(:failed) { create(:equipment, user: owner.user, operator: nil) }

    before do
      EquipmentInspection.create!(equipment: cleared, membership: owner, inspected_by: inspector, form_template: template, is_ok: true, definition: "[]")
      EquipmentInspection.create!(equipment: failed, membership: owner, inspected_by: inspector, form_template: template, is_ok: false, definition: "[]")
    end

    it "finds the equipment without an ok inspection at the operator, never inspected ones included" do
      expect(owner.user.equipment.not_inspected_at(operator)).to contain_exactly(never_inspected, failed)
    end

    it "finds equipment that was cleared at another operator only" do
      other = create(:operator)

      expect(owner.user.equipment.not_inspected_at(other)).to contain_exactly(never_inspected, cleared, failed)
    end
  end
end
