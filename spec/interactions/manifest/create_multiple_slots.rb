# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::CreateMultipleSlots do
  let!(:dropzone) { create(:dropzone, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:dropzone_users) { create_list(:dropzone_user_with_license, 4, dropzone: dropzone, credits: 200) }
  let!(:jump_type) { JumpType.allowed_for(dropzone_users).sample }
  let!(:user_group) do
    dropzone_users.map do |dz_user|
      {
        rig_id: dz_user.user.rigs&.first&.id,
        exit_weight: dz_user.exit_weight,
        dropzone_user_id: dz_user.id
      }
    end
  end
  let!(:plane) { create(:plane, dropzone: dropzone) }
  let!(:plane_load) { create(:load, plane: plane) }

  describe "Manifesting on a load" do
    context "when the user has credits" do
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          ticket_type_id: ticket_type.id,
          jump_type_id: jump_type.id,
          load_id: plane_load.id,
          users: user_group
        )
      end

      it { expect(outcome.result).to be_a Load }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.slots.map(&:order).reject(&:blank?).count).to eq dropzone_users.count }
    end

    context "when the user doesnt have enough credits" do
      before do
        dropzone_users.sample.update(credits: ticket_type.cost - 10)
      end
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          ticket_type_id: ticket_type.id,
          jump_type_id: jump_type.id,
          load_id: plane_load.id,
          users: user_group
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:credits]).not_to be nil }
    end

    context "when the user isnt allowed to manifest with the requested jump type" do
      let!(:forbidden_jump_type) { JumpType.where.not(id: JumpType.allowed_for([dropzone_users.first]).pluck(:id)).sample }
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          ticket_type_id: ticket_type.id,
          jump_type_id: forbidden_jump_type.id,
          load_id: plane_load.id,
          users: user_group
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:jump_type_id]).not_to be nil }
    end

    context "with a tandem passenger" do
      let!(:tandem_ticket) { create(:ticket_type, dropzone: dropzone, is_tandem: true) }
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          ticket_type_id: tandem_ticket.id,
          jump_type_id: jump_type.id,
          load_id: plane_load.id,
          users: user_group.take(2).map do |group|
            group.merge(
              passenger_exit_weight: 50,
              passenger_name: Faker::Name.first_name
            )
          end
        )
      end

      it { expect(outcome.result).to be_a Load }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.slots.map(&:order).reject(&:blank?).count).to eq 2 }
    end
  end
end
