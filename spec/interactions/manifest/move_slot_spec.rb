# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::MoveSlot do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }
  let!(:plane) { create(:plane, dropzone: dropzone) }
  let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:target_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:access_context) do
    u = create(:dropzone_user, dropzone: dropzone)
    u.grant! :createSlot
    u.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(u)
  end

  describe "Moving a slot to another load" do
    context "without specifying a target slot" do
      let!(:source_slot) do
        Manifest::CreateSlot.run!(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
      end
      let!(:outcome) do
        Manifest::MoveSlot.run(
          access_context: access_context,
          source_slot: source_slot,
          target_load: target_load,
        )
      end

      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result).not_to be nil }
    end
  end
end
