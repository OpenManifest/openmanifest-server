# frozen_string_literal: true

require "rails_helper"

RSpec.describe RigInspection, type: :model do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:dropzone) { create(:dropzone) }
  let!(:dropzone_users) { create_list(:dropzone_user, 5, dropzone: dropzone) }
  let!(:dropzone_rigs) { create_list(:rig, 5, dropzone: dropzone) }

  before do
    inspector = create(:dropzone_user, dropzone: dropzone)
    # Create a few different rigs for each user
    dropzone_users.each do |dz_user|
      create_list(:rig, 3, user: dz_user.user)

      # Take 2 random rigs for each user and approve them
      rigs = dz_user.user.rigs.shuffle.take(2)
      rigs.each do |rig|
        create(
          :rig_inspection,
          is_ok: true,
          dropzone_user: dz_user,
          rig: rig,
          inspected_by: inspector,
        )
      end
    end

  end

  describe 'DropzoneUser.approved_rigs' do
    it 'returns 2 approved rigs' do
      dropzone_users.each do |dzu|
        expect(dzu.approved_rigs.count).to eq 2
      end
    end
  end

  describe 'DropzoneUser.available_rigs' do
    it 'returns 2 approved rigs + 5 dropzone rigs' do
      dropzone_users.each do |dzu|
        expect(dzu.dropzone.rigs.count).to eq 5
        expect(dzu.available_rigs.count).to eq 7
      end
    end
  end
end
