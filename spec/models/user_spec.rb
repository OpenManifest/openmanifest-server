# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  provider               :string           default("email"), not null
#  uid                    :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  allow_password_change  :boolean          default(FALSE)
#  remember_created_at    :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  name                   :string
#  nickname               :string
#  image                  :string
#  phone                  :string
#  email                  :string
#  body_mass_kg            :float
#  license_id             :bigint
#  tokens                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  push_token             :string
#  unconfirmed_email      :string
#  time_zone              :string           default("Australia/Brisbane")
#  load_count             :integer          default(0), not null
#  operator_count         :integer          default(0), not null
#  vehicle_count            :integer          default(0), not null
#
require "rails_helper"

RSpec.describe User do
  let!(:operator) do
    # Create an operator
    create(
      :operator,
      name: "rspec",
    )
  end

  let(:membership) do
    user = User.new(
      name: "rspec",
      nickname: "test",
      password: "rspec12345",
      email: "rspec@rspec.spec",
      phone: "123123",
    )
    user.save!

    create(:membership,
           operator: operator,
           user: user,)
  end

  describe "can?" do
    it "has some permissions" do
      expect(membership.permissions).to be_empty
      expect(membership.role_permissions).not_to be_empty
      expect(membership.all_permissions).not_to be_empty
    end

    it "returns false if user lacks permission" do
      expect(membership.can?("updateOperator")).to eq false
    end

    it "returns true if user has permission" do
      expect(membership.can?("createPackjob")).to eq false
      membership.grant!(:createPackjob)
      expect(membership.can?("createPackjob")).to eq true
    end

    it "returns true for all permissions in a users role" do
      membership.user_role.permissions.each do |permission|
        expect(membership.can?(permission.name)).to eq true
      end
    end

    it "returns true for permissions specifically granted to the user" do
    end
  end
end
