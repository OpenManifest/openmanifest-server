# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Operators, type: :request do
    include_context "operator"
    let!(:student) { create(:membership, credits: 100, operator: operator, user: create(:user), user_role: operator.user_roles.default_licensed) }
    let!(:tandem_rig) { create(:rig, rig_type: :tandem, operator: operator) }
    let!(:student_rig) { create(:rig, rig_type: :student, is_public: true, operator: operator) }
    let!(:private_operator_rig) { create(:rig, rig_type: :sport, is_public: false, operator: operator) }
    let!(:occupied_student_rig) { create(:rig, rig_type: :student, is_public: true, operator: operator) }

    let!(:load) { create(:load, plane: plane, created_at: 30.minutes.ago) }
    let!(:slot) { create(:slot, load: load, operator: operator, membership: student, rig: occupied_student_rig, jump_type: JumpType.find_by(slug: :fs)) }

    let!(:uninspected_rig) { create(:rig, rig_type: :sport, user: user) }
    let!(:inspected_rig) { create(:rig, rig_type: :sport, user: user) }
    let!(:rig_inspection) { create(:rig_inspection, is_ok: true, rig: inspected_rig, membership: fun_jumper, inspected_by: instructor) }

    describe "Can select own rig or student rigs" do
      subject do
        execute_query(
          is_tandem: false,
          membership: fun_jumper.id,
          load_id: load.id
        )
      end

      it { is_expected.to include_json(availableRigs: [{ id: inspected_rig.id.to_s }, { id: student_rig.id.to_s }]) }

      it 'cannot select occupied rigs, tandem rigs or rigs without an inspection' do
        [occupied_student_rig, tandem_rig, uninspected_rig].each do |rig|
          is_expected.not_to include_json(availableRigs: [{ id: rig.id.to_s }])
        end
      end
    end

    describe "Can select student rig" do
      context 'but not when the reserve is out of date' do
        before { student_rig.update(repack_expires_at: 1.day.ago) }
        subject do
          execute_query(
            is_tandem: false,
            membership: fun_jumper.reload.id,
            load_id: load.id
          )
        end

        it { is_expected.to include_json(availableRigs: [{ id: inspected_rig.id.to_s }]) }

        it 'cannot select tandem rigs or rigs without an inspection or rigs with reserve out of date' do
          [student_rig, occupied_student_rig, tandem_rig, uninspected_rig].each do |rig|
            is_expected.not_to include_json(availableRigs: [{ id: rig.id.to_s }])
          end
        end
      end

      context 'when the rig is on a load that is cancelled or has landed' do
        before { load.update(state: :landed) }
        let!(:next_load) { create(:load, plane: plane, created_at: 5.minutes.ago) }
        subject do
          execute_query(
            is_tandem: false,
            membership: fun_jumper.reload.id,
            load_id: next_load.id
          )
        end

        it { is_expected.to include_json(availableRigs: [{ id: inspected_rig.id.to_s }, { id: student_rig.id.to_s }, { id: occupied_student_rig.id.to_s }]) }

        it 'cannot select tandem rigs or rigs without an inspection' do
          [tandem_rig, uninspected_rig].each do |rig|
            is_expected.not_to include_json(availableRigs: [{ id: rig.id.to_s }])
          end
        end
      end
    end

    describe "Tandem rigs can only be selected for tandems" do
      subject do
        execute_query(
          is_tandem: true,
          membership: fun_jumper.id,
          load_id: load.id
        )
      end

      it { is_expected.to include_json(availableRigs: [{ id: tandem_rig.id.to_s }]) }

      it 'cannot select any sport rigs' do
        [inspected_rig, uninspected_rig, student_rig, occupied_student_rig].each do |rig|
          is_expected.not_to include_json(availableRigs: [{ id: rig.id.to_s }])
        end
      end
    end

    create_query(:is_tandem, :load_id, :membership) do
      <<~GQL
        query {
          availableRigs(isTandem: #{is_tandem}, loadId: #{load_id}, membership: #{membership}) {
            id
          }
        }
      GQL
    end
  end
end
