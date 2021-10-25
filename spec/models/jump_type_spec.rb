# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id           :bigint           not null, primary key
#  dropzone_id  :bigint           not null
#  seller_type  :string           not null
#  seller_id    :bigint           not null
#  buyer_type   :string           not null
#  buyer_id     :bigint           not null
#  item_type    :string           not null
#  item_id      :bigint           not null
#  order_number :integer          default(1), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "rails_helper"

RSpec.describe JumpType, type: :model do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:dropzone) { create(:dropzone) }
  let!(:user1) { create(:user) }
  let!(:certificate_e_user) { create(:dropzone_user, dropzone: dropzone, user: user1) }
  let!(:certificate_e_federation) { create(:user_federation, user: user1, federation: federation, license: federation.licenses.find_by(name: "Certificate E")) }

  let!(:user2) { create(:user) }
  let!(:certificate_a_user) { create(:dropzone_user, dropzone: dropzone, user: user2) }
  let!(:certificate_a_federation) { create(:user_federation, user: user2, federation: federation, license: federation.licenses.find_by(name: "Certificate A")) }

  let!(:user3) { create(:user) }
  let!(:certificate_c_user) { create(:dropzone_user, dropzone: dropzone, user: user3) }
  let!(:certificate_c_federation) { create(:user_federation, user: user3, federation: federation, license: federation.licenses.find_by(name: "Certificate C")) }

  it "E license user is allowed for any jump" do
    expect(
      JumpType.allowed_for(
        certificate_e_user
      ).pluck(:slug).sort
    ).to eq JumpType.all.pluck(:slug).sort
  end

  it "A license only allowed for flat" do
    expect(
      JumpType.allowed_for(
        certificate_a_user
      ).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "A license and E license user only allowed for A licensed jump" do
    expect(
      JumpType.allowed_for([
        certificate_e_user,
        certificate_a_user
      ]).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "A license, C license and E license user only allowed for A licensed jump" do
    expect(
      JumpType.allowed_for([
        certificate_e_user,
        certificate_c_user,
        certificate_a_user
      ]).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "C license and E license users allowed for C licensed jumps" do
    expect(
      JumpType.allowed_for([
        certificate_e_user,
        certificate_c_user
      ]).pluck(:slug).sort
    ).to eq ["fs", "hp", "hnp", "angle", "freefly", "cam"].sort
  end
end
