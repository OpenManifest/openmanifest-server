# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Operators, type: :request do
    include_context "operator"
    let!(:student) { create(:membership, credits: 100, operator: operator, user: create(:user), user_role: operator.user_roles.default_licensed) }
    let!(:tandem_equipment) { create(:equipment, rig_type: :tandem, operator: operator) }
    let!(:student_equipment) { create(:equipment, rig_type: :student, is_public: true, operator: operator) }
    let!(:private_operator_equipment) { create(:equipment, rig_type: :sport, is_public: false, operator: operator) }
    let!(:occupied_student_equipment) { create(:equipment, rig_type: :student, is_public: true, operator: operator) }

    let!(:load) { create(:load, vehicle: vehicle, created_at: 30.minutes.ago) }
    let!(:slot) { create(:slot, load: load, operator: operator, membership: student, equipment: [occupied_student_equipment], activity_type: ActivityType.find_by(slug: :fs)) }

    let!(:uninspected_equipment) { create(:equipment, rig_type: :sport, user: user) }
    let!(:inspected_equipment) { create(:equipment, rig_type: :sport, user: user) }
    let!(:equipment_inspection) { create(:equipment_inspection, is_ok: true, equipment: inspected_equipment, membership: fun_jumper, inspected_by: instructor) }

    describe "Can select own equipment or student equipment" do
      subject do
        execute_query(
          is_tandem: false,
          membership: fun_jumper.id,
          load_id: load.id
        )
      end

      it { is_expected.to include_json(availableEquipment: [{ id: inspected_equipment.id.to_s }, { id: student_equipment.id.to_s }]) }

      it 'cannot select occupied equipment, tandem equipment or equipment without an inspection' do
        [occupied_student_equipment, tandem_equipment, uninspected_equipment].each do |equipment|
          is_expected.not_to include_json(availableEquipment: [{ id: equipment.id.to_s }])
        end
      end
    end

    describe "Can select student equipment" do
      context 'but not when the reserve is out of date' do
        before { student_equipment.update(service_due_at: 1.day.ago) }
        subject do
          execute_query(
            is_tandem: false,
            membership: fun_jumper.reload.id,
            load_id: load.id
          )
        end

        it { is_expected.to include_json(availableEquipment: [{ id: inspected_equipment.id.to_s }]) }

        it 'cannot select tandem equipment or equipment without an inspection or equipment with reserve out of date' do
          [student_equipment, occupied_student_equipment, tandem_equipment, uninspected_equipment].each do |equipment|
            is_expected.not_to include_json(availableEquipment: [{ id: equipment.id.to_s }])
          end
        end
      end

      context 'when the equipment is on a load that is cancelled or has completed' do
        before { load.update(state: :completed) }
        let!(:next_load) { create(:load, vehicle: vehicle, created_at: 5.minutes.ago) }
        subject do
          execute_query(
            is_tandem: false,
            membership: fun_jumper.reload.id,
            load_id: next_load.id
          )
        end

        it { is_expected.to include_json(availableEquipment: [{ id: inspected_equipment.id.to_s }, { id: student_equipment.id.to_s }, { id: occupied_student_equipment.id.to_s }]) }

        it 'cannot select tandem equipment or equipment without an inspection' do
          [tandem_equipment, uninspected_equipment].each do |equipment|
            is_expected.not_to include_json(availableEquipment: [{ id: equipment.id.to_s }])
          end
        end
      end
    end

    describe "Tandem equipment can only be selected for tandems" do
      subject do
        execute_query(
          is_tandem: true,
          membership: fun_jumper.id,
          load_id: load.id
        )
      end

      it { is_expected.to include_json(availableEquipment: [{ id: tandem_equipment.id.to_s }]) }

      it 'cannot select any sport equipment' do
        [inspected_equipment, uninspected_equipment, student_equipment, occupied_student_equipment].each do |equipment|
          is_expected.not_to include_json(availableEquipment: [{ id: equipment.id.to_s }])
        end
      end
    end

    create_query(:is_tandem, :load_id, :membership) do
      <<~GQL
        query {
          availableEquipment(isTandem: #{is_tandem}, loadId: #{load_id}, membership: #{membership}) {
            id
          }
        }
      GQL
    end
  end
end
