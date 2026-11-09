# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id           :bigint           not null, primary key
#  operator_id  :bigint           not null
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

RSpec.describe ActivityType do
  let!(:certification_body) { CertificationBody.find_by(slug: :apf) }
  let!(:operator) { create(:operator) }
  let!(:user1) { create(:user) }
  let!(:certificate_e_user) do
    create(:membership, operator: operator, user: user1, certification_level: certification_body.certification_levels.find_by(name: "Certificate E"))
  end

  let!(:user2) { create(:user) }
  let!(:certificate_a_user) do
    create(:membership, operator: operator, user: user2, certification_level: certification_body.certification_levels.find_by(name: "Certificate A"))
  end

  let!(:user3) { create(:user) }
  let!(:certificate_c_user) do
    create(:membership, operator: operator, user: user3, certification_level: certification_body.certification_levels.find_by(name: "Certificate C"))
  end

  it "E certification_level user is allowed for any jump" do
    expect(
      ActivityType.allowed_for(
        certificate_e_user
      ).pluck(:slug).sort
    ).to eq ActivityType.all.pluck(:slug).sort
  end

  it "A certification_level only allowed for flat" do
    expect(
      ActivityType.allowed_for(
        certificate_a_user
      ).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "A certification_level and E certification_level user only allowed for A licensed jump" do
    expect(
      ActivityType.allowed_for([
        certificate_e_user,
        certificate_a_user,
      ]).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "A certification_level, C certification_level and E certification_level user only allowed for A licensed jump" do
    expect(
      ActivityType.allowed_for([
        certificate_e_user,
        certificate_c_user,
        certificate_a_user,
      ]).pluck(:slug).sort
    ).to eq ["fs", "hnp", "hp"].sort
  end

  it "C certification_level and E certification_level users allowed for C licensed jumps" do
    expect(
      ActivityType.allowed_for([
        certificate_e_user,
        certificate_c_user,
      ]).pluck(:slug).sort
    ).to eq ["fs", "hp", "hnp", "angle", "freefly", "cam"].sort
  end
end
