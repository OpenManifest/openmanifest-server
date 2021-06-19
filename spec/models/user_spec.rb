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
