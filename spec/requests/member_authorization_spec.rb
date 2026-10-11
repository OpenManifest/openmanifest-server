# frozen_string_literal: true

require "rails_helper"

# P6.3: member and user queries (BUG-002 member resolvers, BUG-013, BUG-093)
RSpec.describe "Member authorization" do
  let(:dropzone) { create(:dropzone, state: "public") }
  let(:other_dropzone) { create(:dropzone, state: "public") }

  def membership(role, dz: dropzone, **attrs)
    user = attrs.delete(:user) || create(:user, phone: "0400 123 456")
    create(:dropzone_user, dropzone: dz, user: user, user_role: dz.user_roles.find_by(name: role), **attrs)
  end

  let!(:owner) { membership("owner") }
  let!(:fun_jumper) { membership("fun_jumper") }
  let!(:student) { membership("student") }
  let!(:foreign_member) { membership("fun_jumper", dz: other_dropzone) }
  let(:stranger) { create(:user) }

  let(:member_query) { "query($id: ID!) { dropzoneUser(id: $id) { id user { id email phone pushToken } } }" }
  let(:list_query) { "query($dropzone: ID!) { dropzoneUsers(dropzone: $dropzone, licensed: false) { edges { node { id } } } }" }

  def graphql(query, as:, variables: {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  def code(json)
    json.dig(:errors, 0, :extensions, :code)
  end

  describe "dropzoneUser(id:)" do
    it "returns your own membership whatever your role" do
      json = graphql(member_query, as: student.user, variables: { id: student.id })

      expect(json.dig(:data, :dropzoneUser, :id)).to eq(student.id.to_s)
    end

    it "returns another member to someone with readUser" do
      expect(graphql(member_query, as: fun_jumper.user, variables: { id: owner.id }).dig(:data, :dropzoneUser, :id)).to eq(owner.id.to_s)
    end

    it "refuses another member to someone without readUser" do
      json = graphql(member_query, as: student.user, variables: { id: owner.id })

      expect(json.dig(:data, :dropzoneUser)).to be_nil
      expect(code(json)).to eq("FORBIDDEN")
    end

    it "refuses a member of another dropzone and a stranger" do
      expect(code(graphql(member_query, as: fun_jumper.user, variables: { id: foreign_member.id }))).to eq("FORBIDDEN")
      expect(code(graphql(member_query, as: stranger, variables: { id: owner.id }))).to eq("FORBIDDEN")
    end
  end

  describe "dropzoneUsers(dropzone:)" do
    it "lists the members for someone with readUser" do
      ids = graphql(list_query, as: owner.user, variables: { dropzone: dropzone.id }).dig(:data, :dropzoneUsers, :edges).map { |edge| edge.dig(:node, :id) }

      expect(ids).to include(fun_jumper.id.to_s, student.id.to_s)
    end

    it "refuses someone without readUser, a member of another dropzone and a stranger" do
      expect(code(graphql(list_query, as: student.user, variables: { dropzone: dropzone.id }))).to eq("FORBIDDEN")
      expect(code(graphql(list_query, as: fun_jumper.user, variables: { dropzone: other_dropzone.id }))).to eq("FORBIDDEN")
      expect(code(graphql(list_query, as: stranger, variables: { dropzone: dropzone.id }))).to eq("FORBIDDEN")
    end
  end

  describe "personal data of a user" do
    before { fun_jumper.user.update!(push_token: "ExponentPushToken[secret]") }

    def user_data(viewer, member)
      graphql(member_query, as: viewer, variables: { id: member.id }).dig(:data, :dropzoneUser, :user)
    end

    it "shows you all of your own" do
      expect(user_data(fun_jumper.user, fun_jumper)).to include(email: fun_jumper.user.email, phone: "0400 123 456", pushToken: "ExponentPushToken[secret]")
    end

    it "shows email and phone, but never the push token, to staff of a shared dropzone" do
      data = user_data(owner.user, fun_jumper)

      expect(data).to include(email: fun_jumper.user.email, phone: "0400 123 456", pushToken: nil)
    end

    it "shows a member without readUser their own email" do
      expect(graphql(member_query, as: student.user, variables: { id: student.id }).dig(:data, :dropzoneUser, :user)).to include(email: student.user.email)
    end

    it "shows a moderator the email and phone, not the push token" do
      moderator = create(:user, moderation_role: :moderator)
      data = user_data(moderator, fun_jumper)

      expect(data).to include(email: fun_jumper.user.email, pushToken: nil)
    end
  end

  describe "the permissions filter" do
    it "finds members whose role grants the permission, and those granted it directly" do
      student.grant!("actAsPilot")
      query = "query($dropzone: ID!, $permissions: [Permission!]) { dropzoneUsers(dropzone: $dropzone, permissions: $permissions, licensed: false) { edges { node { id } } } }"

      by_role = graphql(query, as: owner.user, variables: { dropzone: dropzone.id, permissions: ["updateDropzone"] }).dig(:data, :dropzoneUsers, :edges).map { |edge| edge.dig(:node, :id) }
      direct = graphql(query, as: owner.user, variables: { dropzone: dropzone.id, permissions: ["actAsPilot"] }).dig(:data, :dropzoneUsers, :edges).map { |edge| edge.dig(:node, :id) }

      expect(by_role).to include(owner.id.to_s)
      expect(by_role).not_to include(fun_jumper.id.to_s, student.id.to_s, foreign_member.id.to_s)
      expect(direct).to include(student.id.to_s)
    end
  end
end
