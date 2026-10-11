# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rig do
  describe ".not_inspected_at" do
    let(:dropzone) { create(:dropzone) }
    let(:owner) { create(:dropzone_user, dropzone: dropzone) }
    let(:inspector) { create(:dropzone_user, dropzone: dropzone) }
    let(:template) { create(:form_template, dropzone: dropzone) }
    let!(:never_inspected) { create(:rig, user: owner.user, dropzone: nil) }
    let!(:cleared) { create(:rig, user: owner.user, dropzone: nil) }
    let!(:failed) { create(:rig, user: owner.user, dropzone: nil) }

    before do
      RigInspection.create!(rig: cleared, dropzone_user: owner, inspected_by: inspector, form_template: template, is_ok: true, definition: "[]")
      RigInspection.create!(rig: failed, dropzone_user: owner, inspected_by: inspector, form_template: template, is_ok: false, definition: "[]")
    end

    it "finds the rigs without an ok inspection at the dropzone, never inspected ones included" do
      expect(owner.user.rigs.not_inspected_at(dropzone)).to contain_exactly(never_inspected, failed)
    end

    it "finds a rig that was cleared at another dropzone only" do
      other = create(:dropzone)

      expect(owner.user.rigs.not_inspected_at(other)).to contain_exactly(never_inspected, cleared, failed)
    end
  end
end
