# frozen_string_literal: true

require "rails_helper"

# P6.2: tenant checks on the dropzone, load and setup queries (BUG-002, BUG-003, BUG-004, BUG-090, BUG-095)
RSpec.describe "Query authorization" do
  let(:dropzone) { create(:dropzone, state: "public") }
  let(:other_dropzone) { create(:dropzone, state: "public") }
  let(:plane) { create(:plane, dropzone: dropzone, max_slots: 16) }
  let(:other_plane) { create(:plane, dropzone: other_dropzone, max_slots: 16) }

  let(:member_user) { create(:user) }
  let!(:member) { create(:dropzone_user, dropzone: dropzone, user: member_user, user_role: dropzone.user_roles.find_by(name: "fun_jumper")) }
  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner")) }
  let(:stranger) { create(:user) }

  let!(:load_record) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }

  def codes(json)
    json[:errors].to_a.map { |error| error.dig(:extensions, :code) }
  end

  describe "membership is required" do
    it "lets a member read the dropzone's data" do
      json = client_operation("Load", variables: { id: load_record.id }, as: member_user)

      expect(json.dig(:data, :load, :id)).to eq(load_record.id.to_s)
      expect(codes(json)).to be_empty
    end

    it "refuses a stranger the load, loads, planes, ticket types and extras of a public dropzone" do
      other_plane
      Extra.create!(dropzone: dropzone, name: "Video", cost: 5)

      expect(client_operation("Load", variables: { id: load_record.id }, as: stranger).dig(:data, :load)).to be_nil
      expect(codes(client_operation("Loads", variables: { dropzone: dropzone.id }, as: stranger))).to include("FORBIDDEN")
      expect(client_operation("Planes", variables: { dropzoneId: dropzone.id }, as: stranger).dig(:data, :planes)).to be_nil
      expect(client_operation("TicketTypes", variables: { dropzone: dropzone.id }, as: stranger).dig(:data, :ticketTypes)).to be_nil
      expect(client_operation("TicketTypeExtras", variables: { dropzoneId: dropzone.id }, as: stranger).dig(:errors, 0, :extensions, :code)).to eq("FORBIDDEN")
    end

    it "refuses a former member (soft deleted membership)" do
      member.discard

      expect(client_operation("Planes", variables: { dropzoneId: dropzone.id }, as: member_user).dig(:data, :planes)).to be_nil
    end

    it "answers anonymous callers with an authentication error" do
      expect(codes(client_operation("Planes", variables: { dropzoneId: dropzone.id }))).to include("AUTHENTICATION_ERROR")
      expect(codes(client_operation("TicketTypes", variables: { dropzone: dropzone.id }))).to include("AUTHENTICATION_ERROR")
    end

    it "lets a moderator read any dropzone" do
      moderator = create(:user, moderation_role: :moderator)

      expect(client_operation("Planes", variables: { dropzoneId: dropzone.id }, as: moderator).dig(:data, :planes)).to be_an(Array)
    end

    it "does not create a membership while checking" do
      expect { client_operation("Planes", variables: { dropzoneId: dropzone.id }, as: stranger) }.not_to(change(DropzoneUser, :count))
    end
  end

  describe "masterLog" do
    let(:date) { Date.current.iso8601 }

    it "needs updateDropzone" do
      expect(codes(client_operation("MasterLog", variables: { dropzoneId: dropzone.id, date: date }, as: member_user))).to include("FORBIDDEN")
      expect(codes(client_operation("MasterLog", variables: { dropzoneId: dropzone.id, date: date }, as: owner_user))).to be_empty
    end
  end

  describe "activity" do
    def messages(json)
      json.dig(:data, :activity, :edges).to_a.map { |edge| edge.dig(:node, :message) }
    end

    before do
      %i(user admin system).each do |level|
        Activity::CreateEvent.run!(access_context: ApplicationInteraction::AccessContext.new(owner), level: :info, access_level: level,
                                   message: "#{level} event", resource: dropzone, action: :created, created_by: owner, dropzone: dropzone)
      end
    end

    it "shows a member the access levels their role may view" do
      expect(messages(client_operation("Activity", variables: { dropzone: [dropzone.id] }, as: member_user))).to contain_exactly("user event")
    end

    it "shows an owner everything they may view at their dropzone" do
      expect(messages(client_operation("Activity", variables: { dropzone: [dropzone.id] }, as: owner_user))).to include("user event", "admin event")
    end

    it "refuses a dropzone the caller does not belong to" do
      expect(codes(client_operation("Activity", variables: { dropzone: [other_dropzone.id] }, as: member_user))).to include("FORBIDDEN")
    end

    it "shows nothing to a user without memberships" do
      expect(messages(client_operation("Activity", as: stranger))).to be_empty
    end
  end

  describe "image" do
    it "is gone from the schema" do
      expect(DzSchema.get_field("Query", "image")).to be_nil
    end
  end

  describe "dropzones(state:)" do
    it "filters by state" do
      other_dropzone.update!(state: "private")
      create(:dropzone_user, dropzone: other_dropzone, user: member_user, user_role: other_dropzone.user_roles.find_by(name: "owner"))

      private_ids = client_operation("Dropzones", variables: { state: ["private"] }, as: member_user).dig(:data, :dropzones, :edges).map { |edge| edge.dig(:node, :id) }

      expect(private_ids).to eq([other_dropzone.id.to_s])
    end
  end
end
