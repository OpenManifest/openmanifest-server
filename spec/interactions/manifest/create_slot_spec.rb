# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::CreateSlot do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }

  let!(:gca) { create(:dropzone_user, dropzone: dropzone, user: create(:user, name: "GCA")) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone, user: create(:user, name: "Pilot")) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200) }
  let!(:plane) { create(:plane, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane, gca: gca, pilot: pilot) }
  let!(:access_context) do
    u = create(:dropzone_user, dropzone: dropzone)
    u.grant! :createSlot
    u.grant! :createUserSlot
    ::ApplicationInteraction::AccessContext.new(u)
  end

  describe "Manifesting on a load" do
    context "when the user has credits" do
      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      it { expect(outcome.result).to be_a Slot }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.order).not_to be nil }
      it { expect(outcome.result.order.receipts.count).to eq 1 }
      it { expect(outcome.result.order.transactions.where(status: :reserved).count).to eq 2 }
    end

    context "when the user doesnt have enough credits" do
      before do
        dropzone_user.update(credits: ticket_type.cost - 10)
      end

      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:credits]).not_to be nil }
    end

    context "when the user isnt allowed to manifest with the requested jump type" do
      let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, credits: 200, federation: Federation.find_by(slug: :apf), license: Federation.find_by(slug: :apf).licenses.find_by(name: "Certificate A")) }
      let!(:forbidden_jump_type) { JumpType.where.not(id: JumpType.allowed_for([dropzone_user]).pluck(:id)).sample }
      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: forbidden_jump_type,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:jump_type]).not_to be nil }
    end

    context "when the user is double manifested" do
      before do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
      let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
      let!(:second_load) { create(:load, plane: plane, gca: gca, pilot: pilot) }

      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: second_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      it { expect(outcome.result).not_to be_a Slot }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.full_messages.first).to match(/double-manifest/i) }
    end

    context "when the user is double manifested but allowed to" do
      subject do
        Manifest::CreateSlot.run!(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: second_load,
          exit_weight: dropzone_user.exit_weight
        )
      end

      before do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: ticket_type,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
          exit_weight: dropzone_user.exit_weight
        )
        access_context.subject.grant! :createDoubleSlot
      end

      let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
      let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
      let!(:second_load) { create(:load, plane: plane, gca: gca, pilot: pilot) }

      it { is_expected.to be_a Slot }
      it { expect { subject }.not_to raise_error }
    end

    context "with a tandem passenger" do
      let!(:tandem_ticket) { create(:ticket_type, dropzone: dropzone, is_tandem: true) }
      let!(:outcome) do
        Manifest::CreateSlot.run(
          access_context: access_context,
          ticket_type: tandem_ticket,
          dropzone_user: dropzone_user,
          jump_type: JumpType.allowed_for([dropzone_user]).first,
          load: plane_load,
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
