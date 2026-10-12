# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rig do
  describe ".not_inspected_at" do
    let(:operator) { create(:operator) }
    let(:owner) { create(:membership, operator: operator) }
    let(:inspector) { create(:membership, operator: operator) }
    let(:template) { create(:form_template, operator: operator) }
    let!(:never_inspected) { create(:rig, user: owner.user, operator: nil) }
    let!(:cleared) { create(:rig, user: owner.user, operator: nil) }
    let!(:failed) { create(:rig, user: owner.user, operator: nil) }

    before do
      RigInspection.create!(rig: cleared, membership: owner, inspected_by: inspector, form_template: template, is_ok: true, definition: "[]")
      RigInspection.create!(rig: failed, membership: owner, inspected_by: inspector, form_template: template, is_ok: false, definition: "[]")
    end

    it "finds the rigs without an ok inspection at the operator, never inspected ones included" do
      expect(owner.user.rigs.not_inspected_at(operator)).to contain_exactly(never_inspected, failed)
    end

    it "finds a rig that was cleared at another operator only" do
      other = create(:operator)

      expect(owner.user.rigs.not_inspected_at(other)).to contain_exactly(never_inspected, cleared, failed)
    end
  end
end
