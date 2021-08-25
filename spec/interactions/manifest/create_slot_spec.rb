require 'rails_helper'

RSpec.describe Manifest::CreateSlot do
  let!(:dropzone) { create(:dropzone, credits: 50, ) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }
  let!(:plane) { create(:plane, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane) }

  describe "Manifesting on a load" do
    context 'when the user has credits' do
      let!(:outcome) do
        Manifest::CreateSlot.run(
          ticket_type_id: ticket_type.id,
          dropzone_user_id: dropzone_user.id,
          jump_type_id: JumpType.allowed_for([dropzone_user]).first.id,
          load_id: plane_load.id,
          exit_weight: dropzone_user.exit_weight,
        )
      end

      it { expect(outcome.result).to be_a Slot }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.order).not_to be nil }
      it { expect(outcome.result.order.receipts.count).to eq 1 }
      it { expect(outcome.result.order.transactions.where(status: :reserved).count).to eq 2 }
    end

    context 'when the user doesnt have enough credits' do
      before do
        dropzone_user.update(credits: ticket_type.cost - 10)
      end
      let!(:outcome) do
        Manifest::CreateSlot.run(
          ticket_type_id: ticket_type.id,
          dropzone_user_id: dropzone_user.id,
          jump_type_id: JumpType.allowed_for([dropzone_user]).first.id,
          load_id: plane_load.id,
          exit_weight: dropzone_user.exit_weight,
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:credits]).not_to be nil }
    end

    context 'when the user isnt allowed to manifest with the requested jump type' do
      let!(:forbidden_jump_type) { JumpType.where.not(id: JumpType.allowed_for([dropzone_user]).pluck(:id)).sample }
      let!(:outcome) do
        Manifest::CreateSlot.run(
          ticket_type_id: ticket_type.id,
          dropzone_user_id: dropzone_user.id,
          jump_type_id: forbidden_jump_type.id,
          load_id: plane_load.id,
          exit_weight: dropzone_user.exit_weight,
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:jump_type_id]).not_to be nil }
    end

    context 'with a tandem passenger' do
      let!(:tandem_ticket) { create(:ticket_type, dropzone: dropzone, is_tandem: true) }
      let!(:outcome) do
        Manifest::CreateSlot.run(
          ticket_type_id: tandem_ticket.id,
          dropzone_user_id: dropzone_user.id,
          jump_type_id: JumpType.allowed_for([dropzone_user]).first.id,
          load_id: plane_load.id,
          exit_weight: dropzone_user.exit_weight,
          passenger_exit_weight: dropzone_user.exit_weight,
          passenger_name: Faker::Name.first_name

        )
      end

      it { expect(outcome.result).to be_a Slot }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.passenger_slot).not_to be nil }
      it { expect(outcome.result.order).not_to be nil }
      it { expect(outcome.result.order.receipts.count).to eq 2 }
      it { expect(outcome.result.order.transactions.where(status: :completed).count).to eq 4 }
    end
  end
end
