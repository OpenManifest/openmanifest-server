# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manifest::CreateMultipleSlots do
  let!(:operator) { create(:operator, credits: 50) }
  let!(:ticket_type) { create(:ticket_type, operator: operator) }
  let!(:memberships) { create_list(:membership, 4, operator: operator, credits: 200) }
  let!(:jump_type) { JumpType.allowed_for(memberships).sample }
  let!(:user_group) do
    memberships.map do |dz_user|
      {
        rig: dz_user.user.rigs&.first,
        exit_weight: dz_user.exit_weight,
        membership: dz_user,
      }
    end
  end
  let!(:plane) { create(:plane, operator: operator) }
  let!(:gca) { create(:membership, operator: operator) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:plane_load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:access_context) do
    u = create(:membership, operator: operator)
    u.grant! :createUserSlot
    u.grant! :createSlot
    ApplicationInteraction::AccessContext.new(u)
  end

  describe "Manifesting on a load" do
    context "when the user has credits" do
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          ticket_type: ticket_type,
          jump_type: jump_type,
          load: plane_load,
          users: user_group
        )
      end

      it { expect(outcome.result).to be_a Load }
      it { expect(outcome.valid?).to be true }
      it { expect(outcome.errors).to be_empty }
      it { expect(outcome.result.slots.map(&:order).compact_blank.count).to eq memberships.count }
    end

    context "when the user doesnt have enough credits" do
      before do
        memberships.sample.update(credits: ticket_type.cost - 10)
      end

      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          ticket_type: ticket_type,
          jump_type: jump_type,
          load: plane_load,
          users: user_group
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:credits]).not_to be nil }
    end

    context "when the user isnt allowed to manifest with the requested jump type" do
      let!(:forbidden_jump_type) { JumpType.where.not(id: JumpType.allowed_for([memberships.first]).pluck(:id)).sample }
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          ticket_type: ticket_type,
          jump_type: forbidden_jump_type,
          load: plane_load,
          users: user_group
        )
      end

      it { expect(outcome.result).to be nil }
      it { expect(outcome.valid?).to be false }
      it { expect(outcome.errors).not_to be_empty }
      it { expect(outcome.errors.messages[:jump_type_id]).not_to be nil }
    end

    context "with a tandem passenger" do
      let!(:tandem_ticket) { create(:ticket_type, operator: operator, is_tandem: true) }
      let!(:outcome) do
        Manifest::CreateMultipleSlots.run(
          access_context: access_context,
          ticket_type: tandem_ticket,
          jump_type: jump_type,
          load: plane_load,
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
      it { expect(outcome.result.slots.map(&:order).compact_blank.count).to eq 2 }
    end
  end
end
