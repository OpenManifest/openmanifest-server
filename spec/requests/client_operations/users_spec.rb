# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: users, permissions, federation and notifications" do
  include_context "dropzone"
  include_context "federation_sync"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let(:student_role) { dropzone.user_roles.find_by(name: "student") }

  def member_ids(json, name = :dropzoneUsers)
    json.dig(:data, name, :edges).map { |edge| edge.dig(:node, :id) }
  end

  describe "DropzoneUsers" do
    it "lists the licensed members of the dropzone" do
      json = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id }, as: owner_user)

      expect(member_ids(json)).to match_array([fun_jumper, instructor, owner].map { |member| member.id.to_s })
      expect(json.dig(:data, :dropzoneUsers, :edges, 0, :node)).to include(:role, :license, :user, :hasMembership)
    end

    it "includes unlicensed members when licensed is false" do
      unlicensed = create(:dropzone_user, dropzone: dropzone).tap { |member| member.update!(license: nil) }

      default = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id }, as: owner_user)
      all = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id, licensed: false }, as: owner_user)

      expect(member_ids(default)).not_to include(unlicensed.id.to_s)
      expect(member_ids(all)).to include(unlicensed.id.to_s)
    end

    it "searches by name" do
      json = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id, search: fun_jumper.user.name }, as: owner_user)

      expect(member_ids(json)).to eq([fun_jumper.id.to_s])
    end

    it "filters by a permission granted directly to the member" do
      fun_jumper.grant!("actAsPilot")

      json = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id, permissions: ["actAsPilot"] }, as: owner_user)

      expect(member_ids(json)).to include(fun_jumper.id.to_s)
    end

    it "filters by a permission granted through the member's role" do
      json = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id, permissions: ["createSlot"] }, as: owner_user)

      expect(member_ids(json)).to include(fun_jumper.id.to_s)
    end
  end

  describe "DropzoneUsersDetailed" do
    it "lists members with the detailed fields" do
      json = client_operation("DropzoneUsersDetailed", variables: { dropzoneId: dropzone.id }, as: owner_user)

      expect(member_ids(json)).to include(fun_jumper.id.to_s)
      expect(json.dig(:data, :dropzoneUsers, :edges, 0, :node, :user)).to include(:email, :phone)
    end

    it "requires authentication" do
      json = client_operation("DropzoneUsersDetailed", variables: { dropzoneId: dropzone.id })

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "DropzoneUser" do
    it "returns the member with role, license and user" do
      json = client_operation("DropzoneUser", variables: { id: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :dropzoneUser)).to include(id: fun_jumper.id.to_s)
      expect(json.dig(:data, :dropzoneUser, :role, :name)).to eq("fun_jumper")
      expect(json.dig(:data, :dropzoneUser, :user, :id)).to eq(user.id.to_s)
    end

    it "returns null for an unknown member" do
      expect(client_operation("DropzoneUser", variables: { id: 0 }, as: owner_user).dig(:data, :dropzoneUser)).to be_nil
    end

    it "does not expose a member of another dropzone to a stranger" do
      stranger = create(:user)

      json = client_operation("DropzoneUser", variables: { id: fun_jumper.id }, as: stranger)

      expect(json.dig(:data, :dropzoneUser)).to be_nil
    end
  end

  describe "DropzoneUserDetailed" do
    it "returns the detailed member" do
      json = client_operation("DropzoneUserDetailed", variables: { id: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :dropzoneUser)).to include(id: fun_jumper.id.to_s)
      expect(json.dig(:data, :dropzoneUser, :user)).to include(:email)
    end

    it "requires authentication" do
      expect(client_operation("DropzoneUserDetailed", variables: { id: fun_jumper.id }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "DropzoneUserProfile" do
    it "returns the profile with permissions and equipment" do
      json = client_operation("DropzoneUserProfile", variables: { id: fun_jumper.id }, as: owner_user)

      profile = json.dig(:data, :dropzoneUser)
      expect(profile[:id]).to eq(fun_jumper.id.to_s)
      expect(profile[:permissions]).to include("createSlot")
      expect(profile).to include(:rigInspections)
    end

    it "does not expose the push token of another user" do
      user.update!(push_token: "ExponentPushToken[secret]")

      # No client document selects another user's pushToken, so this uses an ad-hoc query
      post "/graphql",
           params: { query: "query($id: ID!) { dropzoneUser(id: $id) { user { pushToken } } }", variables: { id: fun_jumper.id }.to_json },
           headers: staff_user.create_new_auth_token

      expect(JSON.parse(response.body).dig("data", "dropzoneUser", "user", "pushToken")).to be_nil
    end
  end

  describe "UpdateUser" do
    it "lets a user update their own profile" do
      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, name: "New Name", phone: "0400111222", nickname: "Jumpy" }, as: user)

      expect(json.dig(:data, :updateUser, :errors)).to be_nil
      expect(json.dig(:data, :updateUser, :dropzoneUser, :user)).to include(name: "New Name", phone: "0400111222", nickname: "Jumpy")
      expect(user.reload.name).to eq("New Name")
    end

    it "stores the push token" do
      client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, pushToken: "ExponentPushToken[abc]" }, as: user)

      expect(user.reload.push_token).to eq("ExponentPushToken[abc]")
    end

    it "returns validation errors" do
      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, phone: "" }, as: user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :updateUser)).to include(:errors, :fieldErrors)
    end

    it "returns a field error when the email belongs to another user" do
      other = create(:user)

      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, email: other.email }, as: user)

      expect(json.dig(:data, :updateUser, :fieldErrors, 0, :field)).to eq("email")
    end

    it "lets staff with permission update another member's profile" do
      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, name: "Staff Edit" }, as: owner_user)

      expect(json.dig(:data, :updateUser, :errors)).to be_nil
      expect(user.reload.name).to eq("Staff Edit")
    end

    it "keeps a member's email when it is sent unchanged" do
      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, email: user.email, name: "Same Email" }, as: user)

      expect(json.dig(:data, :updateUser, :errors)).to be_nil
      expect(user.reload.name).to eq("Same Email")
    end

    it "does not let staff edit a user who is a member of several dropzones" do
      create(:dropzone_user, dropzone: create(:dropzone), user: user)

      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, name: "Staff Edit" }, as: owner_user)

      expect(json.dig(:data, :updateUser, :errors).join).to match(/multiple dropzones/)
      expect(user.reload.name).not_to eq("Staff Edit")
    end

    it "does not let staff of another dropzone edit a member" do
      other_dropzone = create(:dropzone, state: "public")
      outsider = create(:user)
      create(:dropzone_user, dropzone: other_dropzone, user: outsider, user_role: other_dropzone.user_roles.find_by(name: "owner"))

      json = client_operation("UpdateUser", variables: { dropzoneUser: fun_jumper.id, name: "Outsider" }, as: outsider)

      expect(json.dig(:data, :updateUser, :errors)).to be_present
      expect(user.reload.name).not_to eq("Outsider")
    end

    it "refuses a jumper editing someone else" do
      json = nil
      begin
        json = client_operation("UpdateUser", variables: { dropzoneUser: instructor.id, name: "Hijacked" }, as: user)
      rescue ArgumentError
        # BUG-038: the permission check itself raises
      end

      expect(staff_user.reload.name).not_to eq("Hijacked")
      expect(json).to be_nil.or(satisfy { |body| body[:errors].present? || body.dig(:data, :updateUser, :errors).present? })
    end
  end

  describe "UpdateDropzoneUser" do
    it "saves the change" do
      client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { credits: 123 } }, as: owner_user)

      expect(fun_jumper.reload.credits).to eq(123)
    end

    it "returns the updated member" do
      json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { credits: 123 } }, as: owner_user)

      expect(json.dig(:data, :updateDropzoneUser, :errors)).to be_nil
      expect(json.dig(:data, :updateDropzoneUser, :dropzoneUser, :credits)).to eq(123)
    end

    it "refuses a jumper without updateUser" do
      json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: instructor.id, attributes: { credits: 1_000_000 } }, as: user)

      expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["You don't have permission to update this"])
      expect(instructor.reload.credits).not_to eq(1_000_000)
    end

    context "with a manager who may grant roles" do
      let(:manager) { create(:user) }
      let!(:manager_member) do
        create(:dropzone_user, dropzone: dropzone, user: manager, user_role: dropzone.user_roles.find_by(name: "manifest")).tap do |member|
          member.grant!("updateUser")
          member.grant!("grantPermission")
        end
      end

      it "assigns a role below their own" do
        role = dropzone.user_roles.find_by(name: "fun_jumper")
        member = create(:dropzone_user, dropzone: dropzone, user_role: student_role)

        json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: member.id, attributes: { userRoleId: role.id } }, as: manager)

        expect(json.dig(:data, :updateDropzoneUser, :errors)).to be_nil
        expect(member.reload.user_role).to eq(role)
      end

      it "cannot change the role of the owner" do
        json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: owner.id, attributes: { userRoleId: student_role.id } }, as: manager)

        expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["You don't have permissions to assign this role"])
        expect(owner.reload.user_role.name).to eq("owner")
      end

      it "cannot assign a role of another dropzone" do
        foreign_role = create(:dropzone).user_roles.find_by(name: "student")

        json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { userRoleId: foreign_role.id } }, as: manager)

        expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["That role does not belong to this dropzone"])
        expect(fun_jumper.reload.user_role).not_to eq(foreign_role)
      end
    end

    it "refuses staff of another dropzone" do
      other_dropzone = create(:dropzone, state: "public")
      outsider = create(:user)
      create(:dropzone_user, dropzone: other_dropzone, user: outsider, user_role: other_dropzone.user_roles.find_by(name: "owner"))

      json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { credits: 1 } }, as: outsider)

      expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["You don't have permission to update this"])
      expect(fun_jumper.reload.credits).not_to eq(1)
    end

    it "refuses a user who is not a member at all" do
      json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { credits: 1 } }, as: create(:user))

      expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["You don't have permission to update this"])
    end

    it "does not touch the member's profile" do
      client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { name: "Renamed", credits: 10 } }, as: owner_user)

      expect(fun_jumper.reload.credits).to eq(10)
      expect(user.reload.name).not_to eq("Renamed")
    end

    it "refuses to assign a role at or above the actor's own" do
      manager = create(:user)
      manager_member = create(:dropzone_user, dropzone: dropzone, user: manager, user_role: dropzone.user_roles.find_by(name: "manifest"))
      manager_member.grant!("updateUser")
      manager_member.grant!("grantPermission")
      owner_role = dropzone.user_roles.find_by(name: "owner")

      json = client_operation("UpdateDropzoneUser", variables: { dropzoneUserId: fun_jumper.id, attributes: { userRoleId: owner_role.id } }, as: manager)

      expect(json.dig(:data, :updateDropzoneUser, :errors)).to eq(["You don't have permissions to assign this role"])
      expect(fun_jumper.reload.user_role).not_to eq(owner_role)
    end
  end

  describe "CreateGhost" do
    let(:variables) { { name: "Gus Ghost", email: "ghost@example.com", role: student_role.id, dropzone: dropzone.id, exitWeight: 70 } }

    it "creates a ghost user and a membership with the given role" do
      json = nil
      expect { json = client_operation("CreateGhost", variables: variables, as: owner_user) }.to change(User, :count).by(1)

      ghost = User.find(json.dig(:data, :createGhost, :user, :id))
      expect(json.dig(:data, :createGhost, :errors)).to be_nil
      expect(ghost.dropzone_users.find_by(dropzone: dropzone).user_role).to eq(student_role)
    end

    it "returns field errors for a duplicate email" do
      create(:user, email: "ghost@example.com")

      json = client_operation("CreateGhost", variables: variables, as: owner_user)

      expect(json.dig(:data, :createGhost, :errors)).to be_present
      expect(json.dig(:data, :createGhost, :user)).to be_nil
    end

    it "refuses a jumper without createUser" do
      json = nil
      expect { json = client_operation("CreateGhost", variables: variables, as: user) }.not_to change(User, :count)

      expect(json[:errors] || json.dig(:data, :createGhost, :errors)).to be_present
    end

    it "does not let the ghost be claimed by anyone who signs up with its email" do
      pending "BUG-012: sign-up reuses a ghost whose unconfirmed_email matches and skips confirmation outside production"
      client_operation("CreateGhost", variables: variables, as: owner_user)
      ghost = User.find_by!(email: "ghost@example.com")

      client_operation("UserSignUp", variables: { email: "ghost@example.com", password: "Password1!", passwordConfirmation: "Password1!", name: "Impostor", phone: "1", exitWeight: 80 })

      expect(ghost.reload.name).to eq("Gus Ghost")
    end
  end

  describe "ArchiveUser" do
    it "archives a member for staff with deleteUser" do
      json = client_operation("ArchiveUser", variables: { id: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :deleteUser, :errors)).to be_nil
      expect(fun_jumper.reload).to be_discarded
    end

    it "lets a user archive their own membership" do
      client_operation("ArchiveUser", variables: { id: fun_jumper.id }, as: user)

      expect(fun_jumper.reload).to be_discarded
    end

    it "answers an unknown member with an error" do
      json = client_operation("ArchiveUser", variables: { id: 0 }, as: owner_user)

      expect(json.dig(:data, :deleteUser, :errors)).to eq(["Member not found"])
    end

    it "reports an error instead of raising when the member is already archived" do
      fun_jumper.discard

      json = client_operation("ArchiveUser", variables: { id: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :deleteUser, :errors)).to eq(["Failed to archive this user"])
    end

    it "refuses a jumper archiving someone else" do
      json = client_operation("ArchiveUser", variables: { id: instructor.id }, as: user)

      expect(json.dig(:data, :deleteUser, :errors)).to be_present
      expect(instructor.reload).not_to be_discarded
    end
  end

  describe "GrantPermission" do
    it "grants a permission to a member" do
      json = client_operation("GrantPermission", variables: { dropzoneUserId: fun_jumper.id, permissionName: "actAsPilot" }, as: owner_user)

      expect(json.dig(:data, :grantPermission, :errors)).to be_nil
      expect(json.dig(:data, :grantPermission, :dropzoneUser, :permissions)).to include("actAsPilot")
    end

    it "refuses a jumper" do
      json = client_operation("GrantPermission", variables: { dropzoneUserId: fun_jumper.id, permissionName: "updateUser" }, as: user)

      expect(json.dig(:data, :grantPermission, :errors)).to eq(["You can't grant permissions for this dropzone"])
      expect(fun_jumper.reload.can?(:updateUser)).to be_falsey
    end
  end

  describe "RevokePermission" do
    it "revokes a permission from a member" do
      fun_jumper.grant!("actAsPilot")

      json = client_operation("RevokePermission", variables: { dropzoneUserId: fun_jumper.id, permissionName: "actAsPilot" }, as: owner_user)

      expect(json.dig(:data, :revokePermission, :errors)).to be_nil
      expect(json.dig(:data, :revokePermission, :dropzoneUser, :permissions)).not_to include("actAsPilot")
    end

    it "refuses a jumper" do
      instructor.grant!("actAsPilot")

      json = client_operation("RevokePermission", variables: { dropzoneUserId: instructor.id, permissionName: "actAsPilot" }, as: user)

      expect(json.dig(:data, :revokePermission, :errors)).to be_present
      expect(instructor.reload.permissions.map(&:name)).to include("actAsPilot")
    end
  end

  describe "JoinFederation" do
    let(:federation) { Federation.find_by(slug: "apf") || Federation.first }
    let(:variables) { { federation: federation.id, uid: "12345", license: federation.licenses.first.id } }

    it "links the caller to the federation" do
      json = client_operation("JoinFederation", variables: variables, as: user)

      expect(json.dig(:data, :joinFederation, :errors)).to be_nil
      expect(json.dig(:data, :joinFederation, :userFederation, :uid)).to eq("12345")
      expect(user.user_federations.count).to eq(1)
    end

    it "works for a user who has not joined any dropzone yet" do
      newcomer = create(:user)

      json = client_operation("JoinFederation", variables: variables, as: newcomer)

      expect(json.dig(:data, :joinFederation, :errors)).to be_nil
    end

    def join_federation_at(dropzone_id, as:)
      query = "mutation($attributes: UserFederationInput!, $dropzone: ID) { joinFederation(input: { attributes: $attributes, dropzone: $dropzone }) { errors userFederation { uid } } }"
      post "/graphql",
           params: { query: query, variables: { attributes: variables, dropzone: dropzone_id }.to_json },
           headers: as.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "logs the join at the dropzone given" do
      other_dropzone = create(:dropzone, state: "public")
      create(:dropzone_user, dropzone: other_dropzone, user: user)

      json = join_federation_at(other_dropzone.id, as: user)

      expect(json.dig(:data, :joinFederation, :errors)).to be_nil
      expect(Activity::Event.where(dropzone: other_dropzone, action: :assigned)).to exist
    end

    it "refuses a dropzone the user is not a member of" do
      json = nil
      expect { json = join_federation_at(create(:dropzone).id, as: user) }.not_to(change { UserFederation.count })

      expect(json.dig(:data, :joinFederation, :errors)).to eq(["You are not a member of that dropzone"])
    end

    it "requires authentication" do
      expect(client_operation("JoinFederation", variables: variables).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Notifications" do
    let!(:ticket_type) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
    let!(:manifest_load) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }

    before { fun_jumper.update!(credits: 300) }

    it "lists the caller's notifications, such as being manifested" do
      client_operation("ManifestUser",
                       variables: {
                         load: manifest_load.id, dropzoneUser: fun_jumper.id, ticketType: ticket_type.id,
                         jumpType: JumpType.allowed_for([fun_jumper]).first.id, exitWeight: 80,
                       },
                       as: owner_user)

      json = client_operation("Notifications", variables: { dropzoneId: dropzone.id }, as: user)

      notifications = json.dig(:data, :dropzone, :currentUser, :notifications, :edges).pluck(:node)
      expect(notifications.pluck(:notificationType)).to include("user_manifested")
      expect(notifications.first[:message]).to match(/manifested on Load/)
    end

    it "is empty for a member without notifications" do
      json = client_operation("Notifications", variables: { dropzoneId: dropzone.id }, as: staff_user)

      expect(json.dig(:data, :dropzone, :currentUser, :notifications, :edges)).to eq([])
    end
  end

  describe "UserUpdated" do
    before { ActionCable.server.pubsub.clear }

    it "validates the subscription document" do
      query = GraphQL::Query.new(DzSchema, ClientOperations.document("UserUpdated"))

      expect(GraphQL::StaticValidation::Validator.new(schema: DzSchema).validate(query)[:errors]).to be_empty
    end

    it "is triggered when a member is updated" do
      client_operation("GrantPermission", variables: { dropzoneUserId: fun_jumper.id, permissionName: "actAsPilot" }, as: owner_user)
      fun_jumper.update!(credits: 10)

      expect(ActionCable.server.pubsub.broadcasts("graphql-event::userUpdated:dropzoneUserId:#{fun_jumper.id}")).not_to be_empty
    end
  end
end
