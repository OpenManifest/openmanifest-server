# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::MoveSlot do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:membership) { create(:membership, operator: operator, credits: 200) }
  let!(:plane) { create(:plane, operator: operator) }
  let!(:gca) { create(:membership, operator: operator) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:target_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:access_context) do
    u = create(:membership, operator: operator)
    u.grant! :createSlot
    u.grant! :createUserSlot
    # P6.5: moving somebody else's slot needs updateUserSlot
    u.grant! :updateUserSlot
    ApplicationInteraction::AccessContext.new(u)
  end

  describe "Moving a slot to another load" do
    context "without specifying a target slot" do
      let!(:source_slot) do
        Manifest::CreateSlot.run!(
          access_context: access_context,
          ticket_type: ticket_type,
          membership: membership,
          jump_type: JumpType.allowed_for([membership]).first,
          load: plane_load,
          exit_weight: membership.exit_weight
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
