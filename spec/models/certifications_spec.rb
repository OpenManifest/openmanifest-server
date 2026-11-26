# frozen_string_literal: true

require "rails_helper"

# P7.13: levels rank against each other across certification bodies, qualifications expire, and tickets and extras ask
# for a rank or a qualification
RSpec.describe "Certifications" do
  let(:apf) { CertificationBody.find_by!(slug: "apf") }
  let(:uspa) { CertificationBody.create!(name: "USPA", slug: "uspa", industry: "skydiving") }
  let!(:uspa_b) { uspa.certification_levels.create!(name: "B licence", rank: 30, equivalence_key: "b") }
  let!(:uspa_d) { uspa.certification_levels.create!(name: "D licence", rank: 50, equivalence_key: "d") }
  before do
    [uspa_b, uspa_d].each { |level| level.permitted_activities.create!(activity_type: ActivityType.find_by!(slug: "fs")) }
  end
  let(:operator) { create(:operator, certification_bodies: [apf, uspa]) }
  let(:user) { create(:user) }
  let(:certificate_a) { apf.certification_levels.find_by!(name: "Certificate A") }
  let(:certificate_c) { apf.certification_levels.find_by!(name: "Certificate C") }

  def join(body, level, who: user)
    create(:user_certification, user: who, certification_body: body, certification_level: level)
  end

  describe CertificationLevel do
    it "orders the levels of the catalogue from the lowest rank" do
      expect(apf.certification_levels.map(&:name).first(3)).to eq(["No license", "Student", "Certificate A"])
      expect(apf.certification_levels.map(&:rank)).to eq(apf.certification_levels.map(&:rank).sort)
    end

    it "has the catalogue's ranks for the APF" do
      expect(apf.certification_levels.pluck(:name, :rank).to_h).to include("No license" => 0, "Student" => 10, "Certificate A" => 20, "Certificate E" => 60)
    end

    it "compares across bodies by rank and by equivalence key" do
      expect(uspa_b.rank).to be > certificate_a.rank
      expect(uspa_b).to be_equivalent_to(apf.certification_levels.find_by!(name: "Certificate B"))
      expect(uspa_b).not_to be_equivalent_to(certificate_a)
    end

    it "needs a rank of zero or more" do
      level = uspa.certification_levels.build(name: "Bad", rank: -1)

      expect(level).not_to be_valid
    end
  end

  describe User do
    it "holds the highest level among the bodies given" do
      join(apf, certificate_a)
      join(uspa, uspa_b)

      expect(user.highest_certification_level).to eq(uspa_b)
      expect(user.highest_certification_level([apf.id])).to eq(certificate_a)
      expect(user.highest_certification_level([])).to be_nil
    end

    it "holds a qualification until it expires" do
      qualification = create(:qualification, certification_body: apf)
      held = create(:user_qualification, user_certification: join(apf, certificate_a), qualification: qualification, expires_at: 1.month.from_now)

      expect(user.qualified_for?(qualification)).to be true
      expect(user.qualified_for?(nil)).to be true

      held.update!(expires_at: 1.day.ago)

      expect(user.qualified_for?(qualification)).to be false
      expect(held).not_to be_current
    end

    it "holds a qualification without an expiry for good" do
      qualification = create(:qualification, certification_body: apf)
      create(:user_qualification, user_certification: join(apf, certificate_a), qualification: qualification, expires_at: nil)

      expect(user.qualified_for?(qualification)).to be true
    end
  end

  describe UserCertification do
    it "refuses a level of another body" do
      held = UserCertification.new(user: user, certification_body: apf, certification_level: uspa_b)

      expect(held).not_to be_valid
      expect(held.errors[:certification_level]).to be_present
    end

    it "gives each membership the highest level at the bodies its operator accepts" do
      membership = create(:membership, operator: operator, user: user, certification_level: nil)

      join(apf, certificate_a)
      expect(membership.reload.certification_level).to eq(certificate_a)

      join(uspa, uspa_d)
      expect(membership.reload.certification_level).to eq(uspa_d)
      expect(membership.certification_rank).to eq(50)
    end

    it "ignores the bodies the operator does not accept" do
      other = create(:operator, certification_bodies: [apf])
      membership = create(:membership, operator: other, user: user, certification_level: nil)

      join(uspa, uspa_d)

      expect(membership.reload.certification_level).to be_nil
      expect(membership.certification_rank).to eq(0)
    end
  end

  describe Operator do
    it "accepts several bodies" do
      expect(operator.certification_bodies).to contain_exactly(apf, uspa)
    end

    it "needs a body when its industry has certifications" do
      operator.certification_bodies = []

      expect(operator).not_to be_valid
    end

    it "needs no body without the certifications module" do
      generic = Setup::Operators::CreateOperator.run!(owner: create(:user), industry: "generic", name: "Generic", time_zone: "UTC")

      expect(generic.certification_bodies).to be_empty
    end
  end

  describe "ticket requirements" do
    let(:qualification) { create(:qualification, certification_body: apf, name: "Tandem rating") }
    let(:membership) { create(:membership, operator: operator, user: user, certification_level: nil) }

    it "asks for the minimum rank across bodies" do
      ticket = create(:ticket_type, operator: operator, min_certification_rank: 30)

      expect(ticket.unmet_certification_requirements(membership)).to eq([:certification_rank])

      join(uspa, uspa_b)

      expect(ticket.unmet_certification_requirements(membership.reload)).to be_empty
    end

    it "asks for a current qualification" do
      ticket = create(:ticket_type, operator: operator, required_qualification: qualification)

      expect(ticket.unmet_certification_requirements(membership)).to eq([:qualification])

      create(:user_qualification, user_certification: join(apf, certificate_c), qualification: qualification, expires_at: 1.week.from_now)

      expect(ticket.unmet_certification_requirements(membership.reload)).to be_empty
    end

    it "fails once the qualification has expired" do
      ticket = create(:ticket_type, operator: operator, required_qualification: qualification)
      create(:user_qualification, user_certification: join(apf, certificate_c), qualification: qualification, expires_at: 1.day.ago)

      expect(ticket.unmet_certification_requirements(membership.reload)).to eq([:qualification])
    end

    it "asks for nothing by default" do
      expect(create(:ticket_type, operator: operator).unmet_certification_requirements(membership)).to be_empty
    end

    it "takes only a qualification of a body the operator accepts" do
      other_body = CertificationBody.create!(name: "Other", slug: "other", industry: "skydiving")
      foreign = create(:qualification, certification_body: other_body)

      expect(build(:ticket_type, operator: operator, required_qualification: foreign)).not_to be_valid
      expect(Extra.new(operator: operator, name: "Foreign", required_qualification: foreign)).not_to be_valid
      expect(Extra.new(operator: operator, name: "Own", required_qualification: qualification)).to be_valid
    end
  end

  describe Manifest::CreateSlot do
    let(:vehicle) { create(:vehicle, operator: operator) }
    let(:gca) { create(:membership, operator: operator) }
    let(:pilot) { create(:membership, operator: operator) }
    let(:vehicle_load) { create(:load, vehicle: vehicle, gca: gca, pilot: pilot) }
    let(:membership) { create(:membership, operator: operator, user: user, credits: 500, certification_level: certificate_a) }
    let(:access_context) do
      staff = create(:membership, operator: operator)
      staff.grant! :createSlot
      staff.grant! :createUserSlot
      ApplicationInteraction::AccessContext.new(staff)
    end
    let(:qualification) { create(:qualification, certification_body: apf, name: "Camera rating") }

    def manifest(ticket, extras: [])
      membership.reload
      Manifest::CreateSlot.run(
        access_context: access_context, ticket_type: ticket, membership: membership, load: vehicle_load,
        activity_type: ActivityType.allowed_for([membership]).first, body_mass_kg: membership.body_mass_kg, extras: extras
      )
    end

    before { join(apf, certificate_a) }

    it "refuses a ticket above the member's rank" do
      outcome = manifest(create(:ticket_type, operator: operator, min_certification_rank: 40))

      expect(outcome).not_to be_valid
      expect(outcome.errors.full_messages.join).to include("missing a certification")
    end

    it "lets a member of a higher rank in, at any body the operator accepts" do
      join(uspa, uspa_d)

      expect(manifest(create(:ticket_type, operator: operator, min_certification_rank: 40))).to be_valid
    end

    it "refuses a ticket whose qualification is missing or expired" do
      ticket = create(:ticket_type, operator: operator, required_qualification: qualification)
      expect(manifest(ticket)).not_to be_valid

      create(:user_qualification, user_certification: UserCertification.find_by!(user: user, certification_body: apf), qualification: qualification, expires_at: 1.day.ago)
      expect(manifest(ticket)).not_to be_valid
    end

    it "lets a member with the qualification in" do
      create(:user_qualification, user_certification: UserCertification.find_by!(user: user, certification_body: apf), qualification: qualification, expires_at: nil)

      expect(manifest(create(:ticket_type, operator: operator, required_qualification: qualification))).to be_valid
    end
  end
end
