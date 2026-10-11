# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: dropzones and access" do
  include_context "dropzone"

  let(:other_dropzone) { create(:dropzone, state: "private") }
  let(:moderator) { create(:user, moderation_role: :moderator) }
  let!(:moderator_member) do
    create(:dropzone_user, dropzone: dropzone, user: moderator, user_role: dropzone.user_roles.find_by(name: "owner"))
  end

  def node_ids(json, *path)
    json.dig(:data, *path, :edges).map { |edge| edge.dig(:node, :id) }
  end

  describe "Dropzones" do
    it "lists public dropzones for any signed-in user" do
      json = client_operation("Dropzones", as: user)

      expect(node_ids(json, :dropzones)).to eq([dropzone.id.to_s])
      expect(json.dig(:data, :dropzones, :edges, 0, :node)).to include(name: dropzone.name, status: "public")
    end

    it "hides private dropzones from users who are not staff there" do
      other_dropzone

      expect(node_ids(client_operation("Dropzones", as: user), :dropzones)).not_to include(other_dropzone.id.to_s)
    end

    it "shows private dropzones to staff and to moderators" do
      create(:dropzone_user, dropzone: other_dropzone, user: staff_user, user_role: other_dropzone.user_roles.find_by(name: "manifest"))

      expect(node_ids(client_operation("Dropzones", as: staff_user), :dropzones)).to include(other_dropzone.id.to_s)
      expect(node_ids(client_operation("Dropzones", as: moderator), :dropzones)).to include(other_dropzone.id.to_s)
    end

    it "filters by state" do
      other_dropzone

      json = client_operation("Dropzones", variables: { state: ["private"] }, as: moderator)

      expect(node_ids(json, :dropzones)).to eq([other_dropzone.id.to_s])
    end

    it "requires authentication" do
      json = client_operation("Dropzones")

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Dropzone" do
    it "returns the extensive dropzone with the caller's membership and settings" do
      json = client_operation("Dropzone", variables: { dropzoneId: dropzone.id }, as: user)

      expect(json.dig(:data, :dropzone)).to include(id: dropzone.id.to_s, name: dropzone.name, status: "public")
      expect(json.dig(:data, :dropzone, :currentUser, :id)).to eq(fun_jumper.id.to_s)
      expect(json.dig(:data, :dropzone, :settings)).to include(:requireMembership, :allowManifestBypass)
      expect(json.dig(:data, :dropzone, :currentConditions)).to include(:id, :winds)
    end

    it "returns the dropzone's time zone, for the app to work out the dropzone's day" do
      dropzone.update!(time_zone: "Australia/Sydney")

      expect(client_operation("Dropzone", variables: { dropzoneId: dropzone.id }, as: user).dig(:data, :dropzone, :timeZone)).to eq("Australia/Sydney")
    end

    it "falls back to Brisbane for a dropzone without a time zone" do
      dropzone.update_columns(time_zone: nil)

      expect(client_operation("Dropzone", variables: { dropzoneId: dropzone.id }, as: user).dig(:data, :dropzone, :timeZone)).to eq("Australia/Brisbane")
    end

    it "does not create a membership when a stranger reads a dropzone" do
      stranger = create(:user)

      expect { client_operation("Dropzone", variables: { dropzoneId: dropzone.id }, as: stranger) }.
        not_to(change { dropzone.dropzone_users.count })
    end

    it "returns null for an unknown dropzone and for a private one the caller cannot see" do
      other_dropzone

      expect(client_operation("Dropzone", variables: { dropzoneId: 0 }, as: user).dig(:data, :dropzone)).to be_nil
      expect(client_operation("Dropzone", variables: { dropzoneId: other_dropzone.id }, as: user).dig(:data, :dropzone)).to be_nil
    end
  end

  describe "DropzoneStatistics" do
    it "returns the dropzone with its statistics" do
      json = client_operation("DropzoneStatistics", variables: { dropzoneId: dropzone.id }, as: moderator)

      expect(json.dig(:data, :dropzone, :id)).to eq(dropzone.id.to_s)
      expect(json.dig(:data, :dropzone)).to have_key(:statistics)
    end

    it "accepts a time range" do
      range = { startTime: 1.week.ago.iso8601, endTime: Time.current.iso8601 }

      json = client_operation("DropzoneStatistics", variables: { dropzoneId: dropzone.id, timeRange: range }, as: moderator)

      expect(json[:errors]).to be_nil
    end
  end

  describe "DropzonesStatistics" do
    it "returns the statistics for each visible dropzone with page info" do
      json = client_operation("DropzonesStatistics", as: moderator)

      expect(node_ids(json, :dropzones)).to include(dropzone.id.to_s)
      expect(json.dig(:data, :dropzones, :pageInfo)).to include(hasNextPage: false)
    end
  end

  describe "CurrentUserPermissions" do
    it "returns the caller's membership, role and permissions" do
      json = client_operation("CurrentUserPermissions", variables: { dropzoneId: dropzone.id }, as: user)

      current = json.dig(:data, :dropzone, :currentUser)
      expect(current[:id]).to eq(fun_jumper.id.to_s)
      expect(current.dig(:role, :name)).to eq("fun_jumper")
      expect(current[:permissions]).to include("createSlot", "readLoad")
      expect(current[:permissions]).not_to include("updateDropzone")
    end
  end

  describe "DropzonePermissions" do
    it "returns the dropzone with every role and its permissions" do
      json = client_operation("DropzonePermissions", variables: { id: dropzone.id }, as: moderator)

      roles = json.dig(:data, :dropzone, :roles)
      expect(roles.pluck(:name)).to include("student", "fun_jumper", "owner")
      expect(roles.find { |role| role[:name] == "student" }[:permissions]).to include("createSlot")
    end
  end

  describe "Roles" do
    it "lists every role of the dropzone" do
      json = client_operation("Roles", variables: { dropzoneId: dropzone.id }, as: moderator)

      expect(json.dig(:data, :dropzone, :roles).pluck(:name)).to include("tandem_passenger", "owner")
    end

    it "lists only roles below the caller's own when selectable" do
      json = client_operation("Roles", variables: { dropzoneId: dropzone.id, selectable: true }, as: user)

      names = json.dig(:data, :dropzone, :roles).pluck(:name)
      expect(names).to include("student")
      expect(names).not_to include("owner", "fun_jumper")
    end
  end

  describe "CreateDropzone" do
    let(:variables) { { name: "New Dropzone", federation: Federation.first.id, primaryColor: "#112233" } }

    it "creates a private dropzone owned by the caller" do
      json = nil
      expect { json = client_operation("CreateDropzone", variables: variables, as: user) }.to change(Dropzone, :count).by(1)

      created = Dropzone.find(json.dig(:data, :createDropzone, :dropzone, :id))
      expect(json.dig(:data, :createDropzone, :dropzone)).to include(name: "New Dropzone", status: "private", primaryColor: "#112233")
      expect(created.dropzone_users.owner.map(&:user)).to eq([user])
    end

    it "requires a name" do
      json = client_operation("CreateDropzone", variables: variables.except(:name), as: user)

      expect(json[:errors].first[:message]).to match(/name/i)
    end

    it "requires authentication" do
      json = client_operation("CreateDropzone", variables: variables)

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "UpdateDropzone" do
    it "updates the dropzone for a user who may edit it" do
      json = client_operation("UpdateDropzone", variables: { id: dropzone.id, attributes: { name: "Renamed", primaryColor: "#445566" } }, as: moderator)

      expect(json.dig(:data, :updateDropzone, :errors)).to be_nil
      expect(json.dig(:data, :updateDropzone, :dropzone)).to include(name: "Renamed", primaryColor: "#445566")
      expect(dropzone.reload.name).to eq("Renamed")
    end

    it "refuses users without permission" do
      json = client_operation("UpdateDropzone", variables: { id: dropzone.id, attributes: { name: "Hijacked" } }, as: user)

      expect(json.dig(:data, :updateDropzone, :errors)).to eq(["You don't have permissions to edit this dropzone"])
      expect(dropzone.reload.name).not_to eq("Hijacked")
    end

    it "uploads a banner image" do
      pending "BUG-041: updateDropzone raises NameError when a banner is supplied"
      banner = "data:image/png;base64,#{Base64.strict_encode64(Rails.public_path.join('favicon.ico').binread)}"

      json = client_operation("UpdateDropzone", variables: { id: dropzone.id, attributes: { name: dropzone.name, banner: banner } }, as: moderator)

      expect(json.dig(:data, :updateDropzone, :errors)).to be_nil
      expect(json.dig(:data, :updateDropzone, :dropzone, :banner)).to be_present
    end
  end

  describe "UpdateVisibility" do
    it "lets a moderator who is a member unpublish a dropzone" do
      json = client_operation("UpdateVisibility", variables: { dropzone: dropzone.id, event: "unpublish" }, as: moderator)

      expect(json.dig(:data, :updateVisibility, :errors)).to be_nil
      expect(json.dig(:data, :updateVisibility, :dropzone, :status)).to eq("private")
      expect(dropzone.reload.state).to eq("private")
    end

    it "lets an owner request publication" do
      dropzone.update!(state: "private")
      owner_user = create(:user)
      create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"))

      json = client_operation("UpdateVisibility", variables: { dropzone: dropzone.id, event: "request_publication" }, as: owner_user)

      expect(json.dig(:data, :updateVisibility, :dropzone, :status)).to eq("in_review")
    end

    it "refuses a jumper" do
      json = client_operation("UpdateVisibility", variables: { dropzone: dropzone.id, event: "unpublish" }, as: user)

      expect(json.dig(:data, :updateVisibility, :errors)).to eq(["You cannot perform this action"])
      expect(dropzone.reload.state).to eq("public")
    end

    it "rejects an unknown event" do
      json = client_operation("UpdateVisibility", variables: { dropzone: dropzone.id, event: "unpublish_everything" }, as: moderator)

      expect(json[:errors]).to be_present
    end

    it "lets a moderator who is not a member publish a dropzone" do
      dropzone.update!(state: "private")
      outsider = create(:user, moderation_role: :moderator)

      json = client_operation("UpdateVisibility", variables: { dropzone: dropzone.id, event: "publish" }, as: outsider)

      expect(json.dig(:data, :updateVisibility, :dropzone, :status)).to eq("public")
    end
  end

  describe "UpdateRole" do
    let(:student_role) { dropzone.user_roles.find_by(name: "student") }

    it "enables a permission on a role for a user who may edit permissions" do
      json = client_operation("UpdateRole", variables: { roleId: student_role.id, permissionName: "readUser", enabled: true }, as: moderator)

      expect(json.dig(:data, :updateRole, :role, :permissions)).to include("readUser")
    end

    it "disables a permission" do
      client_operation("UpdateRole", variables: { roleId: student_role.id, permissionName: "readUser", enabled: true }, as: moderator)
      json = client_operation("UpdateRole", variables: { roleId: student_role.id, permissionName: "readUser", enabled: false }, as: moderator)

      expect(json.dig(:data, :updateRole, :role, :permissions)).not_to include("readUser")
    end

    it "refuses a jumper" do
      json = client_operation("UpdateRole", variables: { roleId: student_role.id, permissionName: "readUser", enabled: true }, as: user)

      expect(json.dig(:data, :updateRole, :role)).to be_nil
      expect(json[:errors] || json.dig(:data, :updateRole, :errors)).to be_present
    end
  end

  describe "RigInspectionTemplate" do
    it "returns the dropzone's template" do
      template = create(:form_template, dropzone: dropzone, definition: '[{"label":"Canopy"}]')
      dropzone.update!(rig_inspection_template: template)

      json = client_operation("RigInspectionTemplate", variables: { dropzoneId: dropzone.id }, as: user)

      expect(json.dig(:data, :dropzone, :rigInspectionTemplate)).to include(id: template.id.to_s, definition: '[{"label":"Canopy"}]')
    end
  end

  describe "UpdateRigInspectionTemplate" do
    let!(:template) { create(:form_template, dropzone: dropzone).tap { |form| dropzone.update!(rig_inspection_template: form) } }

    it "updates the template definition for a user who may edit it" do
      json = client_operation("UpdateRigInspectionTemplate", variables: { dropzoneId: dropzone.id, formId: template.id, definition: '[{"label":"Reserve"}]' }, as: moderator)

      expect(json.dig(:data, :updateFormTemplate, :errors)).to be_nil
      expect(json.dig(:data, :updateFormTemplate, :formTemplate, :definition)).to eq('[{"label":"Reserve"}]')
      expect(template.reload.definition).to eq('[{"label":"Reserve"}]')
    end

    it "refuses a jumper" do
      client_operation("UpdateRigInspectionTemplate", variables: { dropzoneId: dropzone.id, formId: template.id, definition: "hijacked" }, as: user)

      expect(template.reload.definition).not_to eq("hijacked")
    end
  end
end
