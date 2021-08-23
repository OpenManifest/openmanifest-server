require 'rails_helper'

RSpec.describe Loads::Finalize do
  let!(:dropzone) { create(:dropzone, credits: 50, ) }
  let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 10) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane) }
  let!(:slots) do
    dropzone_users = [
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2),
      create(:dropzone_user, dropzone: dropzone, credits: ticket_type.cost * 2)
    ]
    dropzone_users.filter_map do |dz_user|
      dz_user.update!(credits: ticket_type.cost * 2)
      o = Manifest::CreateSlot.run(
        ticket_type_id: ticket_type.id,
        dropzone_user_id: dz_user.id,
        jump_type_id: JumpType.allowed_for([dz_user]).sample.id,
        load_id: plane_load.id,
        exit_weight: dz_user.exit_weight,
      )

      if o.valid?
        o.result
      else
        nil
      end
    end
  end
  let!(:outcome) { Loads::Finalize.run(load_id: plane_load.id) }

  describe "Marking a load as landed" do
    it {
      expect(plane_load.reload.slots.map(&:order).reject(&:blank?).count).to eq 6
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
