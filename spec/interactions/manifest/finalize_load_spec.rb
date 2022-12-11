# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::FinalizeLoad do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:slots) do
    dropzone_users = [
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
    ]
    dropzone_users.filter_map do |dz_user|
      dz_user.update!(credits: ticket_type.cost * 2)
      o = Manifest::CreateSlot.run(
        access_context: access_context,
        ticket_type: ticket_type,
        dropzone_user: dz_user,
        jump_type: JumpType.allowed_for([dz_user]).sample,
        load: plane_load,
        exit_weight: dz_user.exit_weight
      )

      if o.valid?
        o.result
      else
        nil
      end
    end
  end
  let!(:access_context) do
    u = create(:dropzone_user, dropzone: dropzone)
    u.grant! :updateLoad
    ApplicationInteraction::AccessContext.new(u)
  end
  let!(:outcome) { Manifest::FinalizeLoad.run(load: plane_load, access_context: access_context) }

  describe "Marking a load as landed" do
    it {
      expect(plane_load.reload.slots.map(&:order).compact_blank.count).to eq 6
    }
    it { expect(outcome.result).to be_a Load }
    it { expect(outcome.valid?).to be true }
    it {
      puts outcome.errors.full_messages
      expect(outcome.errors).to be_empty
    }
    it "completes all transactions" do
      outcome.result.slots.each do |slot|
        expect(slot.order).not_to be nil
        expect(slot.order.receipts.count).to eq 1
        expect(slot.order.transactions.count).to eq 2
        expect(slot.dropzone_user.credits).to eq (ticket_type.cost * 2) - slot.cost
        expect(slot.order.transactions.where(status: :completed).count).to eq 2
      end
    end
  end
end
