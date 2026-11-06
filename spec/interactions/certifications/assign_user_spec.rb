# frozen_string_literal: true

require "rails_helper"

RSpec.describe Certifications::AssignUser do
  let!(:user) { create(:user) }
  let!(:operator) { create(:operator) }
  let!(:membership) { create(:membership, operator: operator, user: user) }
  let!(:apf_response) do
    [
      {
        "BasicInformtation" => {
          "APFNum" => "21922484", "FirstName" => "Victor", "LastName" => "Rudolfsson",
          "DateOfBirth" => "1990-12-22T00:00:00.000Z", "Gender" => "M",
        }, "JumpRecords" => nil, "WaiverInfo" => nil, "Qualifications" => [{ "Qualification" => "Certificate A", "IssueDate" => "2019-12-24T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "15928" }, { "Qualification" => "Certificate B", "IssueDate" => "2020-07-02T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "10060" }, { "Qualification" => "Certificate C", "IssueDate" => "2020-07-02T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "8693" }, { "Qualification" => "Certificate D", "IssueDate" => "2020-10-06T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "6822" }, { "Qualification" => "Certificate E", "IssueDate" => "2021-05-29T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "3997" }, { "Qualification" => "Display General", "IssueDate" => "2020-12-14T00:00:00.000Z", "ExpiryDate" => "2021-12-31T00:00:00.000Z", "SerialNumber" => "6010" }, { "Qualification" => "Freefly Crest HU", "IssueDate" => "2020-10-06T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "995" }, { "Qualification" => "Sporting Licence", "IssueDate" => "2020-03-03T00:00:00.000Z", "ExpiryDate" => "2022-06-30T00:00:00.000Z", "SerialNumber" => "0" }], "MembershipInfo" => [{ "Name" => "Financial Membership", "Status" => "Active", "ExpiryDate" => "2022-06-30T00:00:00.000Z" }], "BalanceFee" => nil, "ColorCode" => [{ "Code" => "RED", "Message" => "Member has not accepted current club waiver" }],
      },
    ]
  end

  describe "assign a user to APF" do
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
        to_return(body: apf_response.to_json, headers: { "Content-Type" => "application/json" })
      Certifications::AssignUser.run(
        user: user,
        certification_body: CertificationBody.find_by(slug: :apf),
        uid: "21922484",
        access_context: ApplicationInteraction::AccessContext.new(
          membership
        )
      )
    end

    it { expect(user.reload.certification_levels.includes(:certification_body).find_by(certification_body: { slug: :apf }).name).to eq "Certificate E" }
    it { expect(user.reload.qualifications.reload.find_by(name: "Freefly Crest HU")).not_to be nil }
    it { expect(user.reload.qualifications.find_by(name: "Display General")).not_to be nil }
    it { expect(membership.reload.certification_level.id).not_to be nil }
    it {
      expect(membership.reload.certification_level.id).to eq user.reload.certification_levels.includes(:certification_body).find_by(certification_body: { slug: :apf }).id
    }
  end

  describe "a body without a verification provider" do
    let(:body) { CertificationBody.create!(name: "Guild", slug: "guild", industry: "skydiving") }
    let!(:level) { body.certification_levels.create!(name: "Member", rank: 10) }

    it "joins the user at the level and leaves the verification to staff" do
      outcome = described_class.run(
        user: user, certification_body: body, certification_level: level, uid: "G-1", number: "55",
        access_context: ApplicationInteraction::AccessContext.new(membership)
      )

      expect(outcome).to be_valid
      expect(outcome.result).to have_attributes(certification_level: level, uid: "G-1", number: "55", verified_at: nil)
      expect(a_request(:get, /apf.com.au/)).not_to have_been_made
    end
  end

  describe "the APF provider" do
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
        to_return(body: apf_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "is chosen by the body's verification provider and verifies the member" do
      apf = CertificationBody.find_by!(slug: :apf)
      expect(apf.provider).to eq(Certifications::Providers::Apf)

      outcome = described_class.run(
        user: user, certification_body: apf, uid: "21922484", access_context: ApplicationInteraction::AccessContext.new(membership)
      )

      expect(outcome.result).to have_attributes(number: "3997")
      expect(outcome.result).to be_verified
    end

    it "keeps the highest ranking certificate and the qualifications with their expiry" do
      apf = CertificationBody.find_by!(slug: :apf)

      described_class.run(user: user, certification_body: apf, uid: "21922484", access_context: ApplicationInteraction::AccessContext.new(membership))

      held = user.reload.user_qualifications.joins(:qualification).find_by(qualifications: { name: "Display General" })
      expect(held.number).to eq("6010")
      expect(held.expires_at).to eq(Time.utc(2021, 12, 31))
      expect(held).not_to be_current
    end
  end
end
