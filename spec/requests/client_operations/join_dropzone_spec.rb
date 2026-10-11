# frozen_string_literal: true

require "rails_helper"

# P6.4: permission checks never write, users join a dropzone explicitly (BUG-005, BUG-089)
RSpec.describe "Joining a dropzone" do
  let(:dropzone) { create(:dropzone, state: "public") }
  let(:private_dropzone) { create(:dropzone, state: "private") }
  let(:user) { create(:user) }

  def join(dz, as:)
    client_operation("JoinDropzone", variables: { dropzone: dz.id }, as: as)
  end

  describe "User#can?" do
    it "is false without a membership and creates no rows" do
      expect { expect(user.can?(:readLoad, dropzone_id: dropzone.id)).to be(false) }.not_to change(DropzoneUser, :count)
    end

    it "uses the role of an existing membership" do
      create(:dropzone_user, dropzone: dropzone, user: user, user_role: dropzone.user_roles.find_by(name: "owner"))

      expect(user.can?(:updateDropzone, dropzone_id: dropzone.id)).to be(true)
    end

    it "ignores a membership that was removed" do
      member = create(:dropzone_user, dropzone: dropzone, user: user, user_role: dropzone.user_roles.find_by(name: "owner"))
      member.discard

      expect(user.can?(:updateDropzone, dropzone_id: dropzone.id)).to be(false)
    end
  end

  describe "dropzone { currentUser }" do
    let(:query) { "query($id: ID!) { dropzone(id: $id) { currentUser { id } } }" }

    it "is null for a user who has not joined, and nothing is created" do
      expect do
        post "/graphql", params: { query: query, variables: { id: dropzone.id }.to_json }, headers: user.create_new_auth_token
      end.not_to change(DropzoneUser, :count)

      expect(response.parsed_body.dig("data", "dropzone", "currentUser")).to be_nil
    end
  end

  describe "joinDropzone" do
    it "makes the caller a member of a public dropzone with the default role" do
      json = nil
      expect { json = join(dropzone, as: user) }.to change { dropzone.dropzone_users.where(user: user).count }.from(0).to(1)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :joinDropzone, :dropzoneUser, :id)).to eq(dropzone.dropzone_users.find_by(user: user).id.to_s)
      expect(dropzone.dropzone_users.find_by(user: user).user_role).to eq(dropzone.user_roles.default)
    end

    it "is idempotent" do
      first = join(dropzone, as: user).dig(:data, :joinDropzone, :dropzoneUser, :id)

      expect { @second = join(dropzone, as: user).dig(:data, :joinDropzone, :dropzoneUser, :id) }.not_to change(DropzoneUser, :count)
      expect(@second).to eq(first)
    end

    it "records who joined in the dropzone's activity" do
      expect { join(dropzone, as: user) }.to change { Activity::Event.where(dropzone: dropzone).count }.by(1)
    end

    it "refuses a private dropzone" do
      json = nil
      expect { json = join(private_dropzone, as: user) }.not_to change(DropzoneUser, :count)

      expect(json.dig(:data, :joinDropzone, :errors)).to eq(["This dropzone cannot be joined"])
    end

    it "lets a moderator join a private dropzone" do
      moderator = create(:user, moderation_role: :moderator)

      expect { join(private_dropzone, as: moderator) }.to change { private_dropzone.dropzone_users.where(user: moderator).count }.by(1)
    end

    it "does not let a member of a private dropzone lose or duplicate their membership" do
      create(:dropzone_user, dropzone: private_dropzone, user: user, user_role: private_dropzone.user_roles.find_by(name: "owner"))

      expect { join(private_dropzone, as: user) }.not_to change(DropzoneUser, :count)
    end

    it "answers an unknown dropzone with an error" do
      json = client_operation("JoinDropzone", variables: { dropzone: 0 }, as: user)

      expect(json.dig(:data, :joinDropzone, :errors)).to eq(["This dropzone cannot be joined"])
    end

    it "needs a logged in user" do
      expect(client_operation("JoinDropzone", variables: { dropzone: dropzone.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end
end
