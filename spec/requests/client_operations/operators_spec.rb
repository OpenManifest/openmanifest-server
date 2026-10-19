# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: operators and access" do
  include_context "operator"

  let(:other_operator) { create(:operator, state: "private") }
  let(:moderator) { create(:user, moderation_role: :moderator) }
  let!(:moderator_member) do
    create(:membership, operator: operator, user: moderator, user_role: operator.user_roles.find_by(name: "owner"))
  end

  def node_ids(json, *path)
    json.dig(:data, *path, :edges).map { |edge| edge.dig(:node, :id) }
  end

  describe "Operators" do
    it "lists public operators for any signed-in user" do
      json = client_operation("Operators", as: user)

      expect(node_ids(json, :operators)).to eq([operator.id.to_s])
      expect(json.dig(:data, :operators, :edges, 0, :node)).to include(name: operator.name, status: "public")
    end

    it "hides private operators from users who are not staff there" do
      other_operator

      expect(node_ids(client_operation("Operators", as: user), :operators)).not_to include(other_operator.id.to_s)
    end

    it "shows private operators to staff and to moderators" do
      create(:membership, operator: other_operator, user: staff_user, user_role: other_operator.user_roles.find_by(name: "manifest"))

      expect(node_ids(client_operation("Operators", as: staff_user), :operators)).to include(other_operator.id.to_s)
      expect(node_ids(client_operation("Operators", as: moderator), :operators)).to include(other_operator.id.to_s)
    end

    it "filters by state" do
      other_operator

      json = client_operation("Operators", variables: { state: ["private"] }, as: moderator)

      expect(node_ids(json, :operators)).to eq([other_operator.id.to_s])
    end

    it "requires authentication" do
      json = client_operation("Operators")

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "Operator" do
    it "returns the extensive operator with the caller's membership and settings" do
      json = client_operation("Operator", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :operator)).to include(id: operator.id.to_s, name: operator.name, status: "public")
      expect(json.dig(:data, :operator, :currentUser, :id)).to eq(fun_jumper.id.to_s)
      expect(json.dig(:data, :operator, :settings)).to include(:requireMembership, :allowManifestBypass)
      expect(json.dig(:data, :operator, :currentConditions)).to include(:id, :winds)
    end

    it "returns the operator's time zone, for the app to work out the operator's day" do
      operator.update!(time_zone: "Australia/Sydney")

      expect(client_operation("Operator", variables: { operatorId: operator.id }, as: user).dig(:data, :operator, :timeZone)).to eq("Australia/Sydney")
    end

    it "does not create a membership when a stranger reads an operator" do
      stranger = create(:user)

      expect { client_operation("Operator", variables: { operatorId: operator.id }, as: stranger) }.
        not_to(change { operator.memberships.count })
    end

    it "returns null for an unknown operator and for a private one the caller cannot see" do
      other_operator

      expect(client_operation("Operator", variables: { operatorId: 0 }, as: user).dig(:data, :operator)).to be_nil
      expect(client_operation("Operator", variables: { operatorId: other_operator.id }, as: user).dig(:data, :operator)).to be_nil
    end
  end

  describe "OperatorStatistics" do
    it "returns the operator with its statistics" do
      json = client_operation("OperatorStatistics", variables: { operatorId: operator.id }, as: moderator)

      expect(json.dig(:data, :operator, :id)).to eq(operator.id.to_s)
      expect(json.dig(:data, :operator)).to have_key(:statistics)
    end

    it "accepts a time range" do
      range = { startTime: 1.week.ago.iso8601, endTime: Time.current.iso8601 }

      json = client_operation("OperatorStatistics", variables: { operatorId: operator.id, timeRange: range }, as: moderator)

      expect(json[:errors]).to be_nil
    end
  end

  describe "OperatorsStatistics" do
    it "returns the statistics for each visible operator with page info" do
      json = client_operation("OperatorsStatistics", as: moderator)

      expect(node_ids(json, :operators)).to include(operator.id.to_s)
      expect(json.dig(:data, :operators, :pageInfo)).to include(hasNextPage: false)
    end
  end

  describe "CurrentUserPermissions" do
    it "returns the caller's membership, role and permissions" do
      json = client_operation("CurrentUserPermissions", variables: { operatorId: operator.id }, as: user)

      current = json.dig(:data, :operator, :currentUser)
      expect(current[:id]).to eq(fun_jumper.id.to_s)
      expect(current.dig(:role, :name)).to eq("fun_jumper")
      expect(current[:permissions]).to include("createSlot", "readLoad")
      expect(current[:permissions]).not_to include("updateOperator")
    end
  end

  describe "OperatorPermissions" do
    it "returns the operator with every role and its permissions" do
      json = client_operation("OperatorPermissions", variables: { id: operator.id }, as: moderator)

      roles = json.dig(:data, :operator, :roles)
      expect(roles.pluck(:name)).to include("student", "fun_jumper", "owner")
      expect(roles.find { |role| role[:name] == "student" }[:permissions]).to include("createSlot")
    end
  end

  describe "Roles" do
    it "lists every role of the operator" do
      json = client_operation("Roles", variables: { operatorId: operator.id }, as: moderator)

      expect(json.dig(:data, :operator, :roles).pluck(:name)).to include("tandem_guest", "owner")
    end

    it "lists only roles below the caller's own when selectable" do
      json = client_operation("Roles", variables: { operatorId: operator.id, selectable: true }, as: user)

      names = json.dig(:data, :operator, :roles).pluck(:name)
      expect(names).to include("student")
      expect(names).not_to include("owner", "fun_jumper")
    end
  end

  describe "CreateOperator" do
    let(:variables) { { industry: "SKYDIVING", name: "New Operator", certificationBodyIds: [CertificationBody.first.id], timeZone: "Australia/Brisbane", primaryColor: "#112233" } }

    it "creates a private operator owned by the caller" do
      json = nil
      expect { json = client_operation("CreateOperator", variables: variables, as: user) }.to change(Operator, :count).by(1)

      created = Operator.find(json.dig(:data, :createOperator, :operator, :id))
      expect(json.dig(:data, :createOperator, :operator)).to include(name: "New Operator", status: "private", primaryColor: "#112233")
      expect(created.memberships.owner.map(&:user)).to eq([user])
    end

    it "stores the banner" do
      json = client_operation("CreateOperator", variables: variables.merge(banner: image_data_url("jpg")), as: user)

      expect(json.dig(:data, :createOperator, :errors)).to be_nil
      expect(Operator.find(json.dig(:data, :createOperator, :operator, :id)).banner).to be_attached
    end

    it "creates no operator for a banner that is not a PNG, JPEG or WebP" do
      json = nil
      expect { json = client_operation("CreateOperator", variables: variables.merge(banner: image_data_url("gif")), as: user) }.not_to change(Operator, :count)

      expect(json.dig(:data, :createOperator, :fieldErrors, 0)).to include(field: "banner", message: "The image must be a PNG, JPEG or WebP")
    end

    it "requires a name" do
      json = client_operation("CreateOperator", variables: variables.except(:name), as: user)

      expect(json[:errors].first[:message]).to match(/name/i)
    end

    it "requires authentication" do
      json = client_operation("CreateOperator", variables: variables)

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "UpdateOperator" do
    it "sets the call schedule, which the operator then reports" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, settings: { callScheduleMinutes: [25, 5] } } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to be_nil
      expect(operator.reload.call_schedule_minutes).to eq([25, 5])
      expect(json.dig(:data, :updateOperator, :operator, :callScheduleMinutes)).to eq([25, 5])
    end

    it "changes the certification bodies the operator accepts" do
      uspa = CertificationBody.create!(name: "USPA", slug: "uspa", industry: "skydiving")
      apf = CertificationBody.find_by!(slug: "apf")

      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, certificationBodyIds: [apf.id, uspa.id] } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to be_nil
      expect(json.dig(:data, :updateOperator, :operator, :certificationBodies).pluck(:slug)).to contain_exactly("apf", "uspa")
      expect(operator.reload.certification_bodies).to contain_exactly(apf, uspa)

      client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, certificationBodyIds: [uspa.id] } }, as: moderator)
      expect(operator.reload.certification_bodies).to eq([uspa])
    end

    it "refuses to leave an operator with certifications without a body" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, certificationBodyIds: [] } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :operator)).to be_nil
      expect(operator.reload.certification_bodies).not_to be_empty
    end

    it "sets the units and the currency the operator shows" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, currency: "NZD", settings: { units: { altitude: "m", mass: "lb" } } } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to be_nil
      expect(json.dig(:data, :updateOperator, :operator)).to include(currency: "NZD", units: include("altitude" => "m", "mass" => "lb", "speed" => "kn"))
      expect(operator.reload).to have_attributes(currency: "NZD")
    end

    it "refuses a unit the quantity does not have, and a currency that is not an ISO code" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, settings: { units: { mass: "ft" } } } }, as: moderator)
      expect(json.dig(:data, :updateOperator, :errors).join).to include("mass in ft")

      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, currency: "dollars" } }, as: moderator)
      expect(json.dig(:data, :updateOperator, :operator)).to be_nil
      expect(operator.reload.currency).to eq("AUD")
    end

    it "refuses a call schedule that is not whole minutes, longest first" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, settings: { callScheduleMinutes: [5, 25] } } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :operator)).to be_nil
      expect(json.dig(:data, :updateOperator, :errors).join).to include("call schedule")
    end
    it "updates the operator for a user who may edit it" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: "Renamed", primaryColor: "#445566" } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to be_nil
      expect(json.dig(:data, :updateOperator, :operator)).to include(name: "Renamed", primaryColor: "#445566")
      expect(operator.reload.name).to eq("Renamed")
    end

    it "refuses users without permission" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: "Hijacked" } }, as: user)

      expect(json.dig(:data, :updateOperator, :errors)).to eq(["You don't have permissions to edit this operator"])
      expect(operator.reload.name).not_to eq("Hijacked")
    end

    it "uploads a banner image" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, banner: image_data_url("png") } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to be_nil
      expect(operator.reload.banner).to be_attached
      expect(operator.banner.content_type).to eq("image/png")
    end

    it "refuses a banner that is not a PNG, JPEG or WebP" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: "Renamed", banner: image_data_url("gif") } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :fieldErrors, 0)).to include(field: "banner", message: "The image must be a PNG, JPEG or WebP")
      expect(operator.reload.banner).not_to be_attached
      expect(operator.name).not_to eq("Renamed")
    end

    it "refuses a banner that is not an image at all" do
      json = client_operation("UpdateOperator", variables: { id: operator.id, attributes: { name: operator.name, banner: data_url_of("<html></html>") } }, as: moderator)

      expect(json.dig(:data, :updateOperator, :errors)).to eq(["The image must be a PNG, JPEG or WebP"])
    end

    describe "requesting publication" do
      let(:private_operator) { create(:operator, state: "private") }
      let(:owner_user) { create(:user) }
      let!(:owner) { create(:membership, operator: private_operator, user: owner_user, user_role: private_operator.user_roles.find_by(name: "owner")) }
      let(:administrator) { create(:user, moderation_role: :administrator) }
      let!(:administrator_member) { create(:membership, operator: private_operator, user: administrator, user_role: private_operator.user_roles.find_by(name: "admin")) }

      def request_publication
        client_operation("UpdateOperator", variables: { id: private_operator.id, attributes: { name: private_operator.name, requestPublication: true } }, as: owner_user)
      end

      it "tells the moderators who are members of the operator, and logs it" do
        json = nil
        expect { json = request_publication }.to change { Notification.where(notification_type: :publication_requested, received_by: administrator_member).count }.by(1)

        expect(json.dig(:data, :updateOperator, :errors)).to be_nil
        expect(private_operator.reload.state).to eq("in_review")
        expect(Notification.last).to have_attributes(sent_by: owner, resource: private_operator, message: "Operator #{private_operator.name} has requested publication")
        expect(Activity::Event.where(operator: private_operator).pluck(:message)).to include("#{owner_user.name} requested publication of #{private_operator.name}")
      end

      it "does not tell anybody twice" do
        request_publication

        expect { request_publication }.not_to(change { Notification.count })
      end

      it "does not tell people who are not moderators" do
        request_publication

        expect(Notification.where(notification_type: :publication_requested).pluck(:received_by_id)).to eq([administrator_member.id])
      end
    end
  end

  describe "UpdateVisibility" do
    it "lets a moderator who is a member unpublish an operator" do
      json = client_operation("UpdateVisibility", variables: { operator: operator.id, event: "unpublish" }, as: moderator)

      expect(json.dig(:data, :updateVisibility, :errors)).to be_nil
      expect(json.dig(:data, :updateVisibility, :operator, :status)).to eq("private")
      expect(operator.reload.state).to eq("private")
    end

    it "lets an owner request publication" do
      operator.update!(state: "private")
      owner_user = create(:user)
      create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"))

      json = client_operation("UpdateVisibility", variables: { operator: operator.id, event: "request_publication" }, as: owner_user)

      expect(json.dig(:data, :updateVisibility, :operator, :status)).to eq("in_review")
    end

    it "refuses a jumper" do
      json = client_operation("UpdateVisibility", variables: { operator: operator.id, event: "unpublish" }, as: user)

      expect(json.dig(:data, :updateVisibility, :errors)).to eq(["You cannot perform this action"])
      expect(operator.reload.state).to eq("public")
    end

    it "rejects an unknown event" do
      json = client_operation("UpdateVisibility", variables: { operator: operator.id, event: "unpublish_everything" }, as: moderator)

      expect(json[:errors]).to be_present
    end

    it "lets a moderator who is not a member publish an operator" do
      operator.update!(state: "private")
      outsider = create(:user, moderation_role: :moderator)

      json = client_operation("UpdateVisibility", variables: { operator: operator.id, event: "publish" }, as: outsider)

      expect(json.dig(:data, :updateVisibility, :operator, :status)).to eq("public")
    end
  end

  describe "UpdateRole" do
    let(:student_role) { operator.user_roles.find_by(name: "student") }

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

  def rig_kind
    operator.equipment_kinds.find_by!(key: "rig")
  end

  describe "EquipmentInspectionTemplate" do
    it "returns the operator's template" do
      template = rig_kind.inspection_form_template
      template.update!(definition: '[{"label":"Canopy"}]')

      json = client_operation("EquipmentInspectionTemplate", variables: { operatorId: operator.id }, as: user)

      kinds = json.dig(:data, :operator, :equipmentKinds)
      expect(kinds.find { |kind| kind[:key] == "rig" }[:inspectionFormTemplate]).to include(id: template.id.to_s, definition: '[{"label":"Canopy"}]')
    end
  end

  describe "UpdateEquipmentInspectionTemplate" do
    let!(:template) { rig_kind.inspection_form_template }

    it "updates the template definition for a user who may edit it" do
      json = client_operation("UpdateEquipmentInspectionTemplate", variables: { operatorId: operator.id, formId: template.id, definition: '[{"label":"Reserve"}]' }, as: moderator)

      expect(json.dig(:data, :updateFormTemplate, :errors)).to be_nil
      expect(json.dig(:data, :updateFormTemplate, :formTemplate, :definition)).to eq('[{"label":"Reserve"}]')
      expect(template.reload.definition).to eq('[{"label":"Reserve"}]')
    end

    it "refuses a jumper" do
      client_operation("UpdateEquipmentInspectionTemplate", variables: { operatorId: operator.id, formId: template.id, definition: "hijacked" }, as: user)

      expect(template.reload.definition).not_to eq("hijacked")
    end
  end
end
