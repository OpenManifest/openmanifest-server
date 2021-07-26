# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
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
#  exit_weight            :float
#  license_id             :integer
#  tokens                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  push_token             :string
#  unconfirmed_email      :string
#  time_zone              :string           default("Australia/Brisbane")
#
require 'rails_helper'

RSpec.describe User, type: :model do
  before(:each) do
    # Create a dropzone
    Dropzone.find_or_create_by(
      name: "rspec",
      federation: Federation.first
    )
  end

  let(:dropzone_user) do
    user = User.new(
      name: "rspec",
      nickname: "test",
      password: "rspec12345",
      email: "rspec@rspec.spec",
      phone: "123123",
    )
    user.save!

    Dropzone.first.dropzone_users.find_or_create_by!(
      user: user,
    )
  end

  describe "can?" do
    it "has some permissions" do
      expect(dropzone_user.permissions).to be_empty
      expect(dropzone_user.role_permissions).not_to be_empty
      expect(dropzone_user.all_permissions).not_to be_empty
    end

    it "returns false if user lacks permission" do
      expect(dropzone_user.can?("updateDropzone")).to eq false
    end

    it "returns true if user has permission" do
      expect(dropzone_user.can?("createPackjob")).to eq false
      dropzone_user.grant!(:createPackjob)
      expect(dropzone_user.can?("createPackjob")).to eq true
    end

    it "returns true for all permissions in a users role" do
      dropzone_user.user_role.permissions.each do |permission|
        expect(dropzone_user.can?(permission.name)).to eq true
      end
    end

    it "returns true for permissions specifically granted to the user" do
    end
  end
end
