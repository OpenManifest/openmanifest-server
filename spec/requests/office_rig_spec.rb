# frozen_string_literal: true

require "rails_helper"

# UB.2: staff with updateUser run a member's personal rigs from the office; nobody else touches them
RSpec.describe "Office rig management" do
  let(:dropzone) { create(:dropzone, state: "public") }
  let(:other_dropzone) { create(:dropzone, state: "public") }

  let(:staff_user) { create(:user) }
  let!(:staff) { create(:dropzone_user, dropzone: dropzone, user: staff_user, user_role: dropzone.user_roles.find_by(name: "manifest")) }
  let(:member_user) { create(:user) }
  let!(:member) { create(:dropzone_user, dropzone: dropzone, user: member_user, user_role: dropzone.user_roles.find_by(name: "fun_jumper")) }
  let(:jumper_user) { create(:user) }
  let!(:jumper) { create(:dropzone_user, dropzone: dropzone, user: jumper_user, user_role: dropzone.user_roles.find_by(name: "fun_jumper")) }
  let(:foreign_staff_user) { create(:user) }
  let!(:foreign_staff) do
    create(:dropzone_user, dropzone: other_dropzone, user: foreign_staff_user, user_role: other_dropzone.user_roles.find_by(name: "owner"))
  end
  let!(:rig) { create(:rig, user: member_user, dropzone: nil, name: "Original", repack_expires_at: 3.months.from_now) }

  def create_rig(as:, user: member_user)
    client_operation("CreateRig", variables: {
      name: "Office rig", make: "Aerodyne", model: "Smart", serial: "S-1", rigType: "tandem",
      canopySize: 190, userId: user.id, repackExpiresAt: 3.months.from_now.to_i,
    }, as: as)
  end

  def update_rig(as:, target: rig)
    client_operation("UpdateRig", variables: { id: target.id, name: "Renamed" }, as: as)
  end

  def archive_rig(as:, target: rig)
    client_operation("ArchiveRig", variables: { id: target.id }, as: as)
  end

  it "has the staff role holding updateUser and the jumper role not" do
    expect(staff.can?(:updateUser)).to be(true)
    expect(jumper.can?(:updateUser)).to be(false)
    expect(foreign_staff.can?(:updateUser)).to be(true)
  end

  describe "staff of the member's dropzone" do
    it "creates a rig for the member" do
      json = create_rig(as: staff_user)

      expect(json.dig(:data, :createRig, :errors)).to be_blank
      expect(member_user.rigs.reload.pluck(:name)).to include("Office rig")
    end

    it "updates the member's rig" do
      expect(update_rig(as: staff_user).dig(:data, :updateRig, :errors)).to be_blank
      expect(rig.reload.name).to eq("Renamed")
    end

    it "archives the member's rig" do
      expect(archive_rig(as: staff_user).dig(:data, :archiveRig, :errors)).to be_blank
      expect(rig.reload).to be_discarded
    end
  end

  describe "everybody else" do
    it "refuses staff of another dropzone" do
      create_rig(as: foreign_staff_user)
      update_rig(as: foreign_staff_user)
      archive_rig(as: foreign_staff_user)

      expect(member_user.rigs.reload.pluck(:name)).to eq(["Original"])
      expect(rig.reload).to have_attributes(name: "Original", discarded_at: nil)
    end

    it "refuses a fun jumper touching another member's rig" do
      expect(create_rig(as: jumper_user).dig(:data, :createRig, :rig)).to be_nil
      expect(update_rig(as: jumper_user).dig(:data, :updateRig, :rig)).to be_nil
      expect(archive_rig(as: jumper_user).dig(:data, :archiveRig, :rig)).to be_nil

      expect(member_user.rigs.reload.pluck(:name)).to eq(["Original"])
      expect(rig.reload).to have_attributes(name: "Original", discarded_at: nil)
    end

    it "refuses staff when the rig's owner is not a member of their dropzone" do
      stranger = create(:user)
      stranger_rig = create(:rig, user: stranger, dropzone: nil, name: "Stranger")

      expect(create_rig(as: staff_user, user: stranger).dig(:data, :createRig, :rig)).to be_nil
      expect(update_rig(as: staff_user, target: stranger_rig).dig(:data, :updateRig, :rig)).to be_nil
      expect(archive_rig(as: staff_user, target: stranger_rig).dig(:data, :archiveRig, :rig)).to be_nil
      expect(stranger_rig.reload).to have_attributes(name: "Stranger", discarded_at: nil)
    end
  end

  it "still lets members manage their own rigs" do
    expect(update_rig(as: member_user).dig(:data, :updateRig, :errors)).to be_blank
    expect(rig.reload.name).to eq("Renamed")
    expect(archive_rig(as: member_user).dig(:data, :archiveRig, :errors)).to be_blank
    expect(rig.reload).to be_discarded
  end
end
