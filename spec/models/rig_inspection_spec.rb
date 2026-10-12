# frozen_string_literal: true

require "rails_helper"

RSpec.describe RigInspection do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:operator) { create(:operator) }
  let!(:memberships) { create_list(:membership, 5, operator: operator) }
  let!(:operator_rigs) { create_list(:rig, 5, operator: operator, is_public: true) }

  before do
    inspector = create(:membership, operator: operator)
    # Create a few different rigs for each user
    memberships.each do |dz_user|
      create_list(:rig, 3, user: dz_user.user)

      # Take 2 random rigs for each user and approve them
      rigs = dz_user.user.rigs.shuffle.take(2)
      rigs.each do |rig|
        create(
          :rig_inspection,
          is_ok: true,
          membership: dz_user,
          rig: rig,
          inspected_by: inspector,
        )
      end
    end
  end

  describe "Membership.approved_rigs" do
    it "returns 2 approved rigs" do
      memberships.each do |dzu|
        expect(dzu.approved_rigs.count).to eq 2
      end
    end
  end

  describe "Membership.available_rigs" do
    it "returns 2 approved rigs + 5 operator rigs" do
      memberships.each do |dzu|
        expect(dzu.operator.rigs.count).to eq 5
        expect(dzu.available_rigs.count).to eq 7
      end
    end
  end
end
