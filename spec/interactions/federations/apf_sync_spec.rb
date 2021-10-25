# frozen_string_literal: true

require "rails_helper"

RSpec.describe Federations::ApfSync do
  let!(:user) { create(:user) }
  let!(:dropzone) { create(:dropzone) }
  let!(:dropzone_user) { create(:dropzone_user, dropzone: dropzone, user: user) }
  let!(:user_federation) { create(:user_federation, federation: Federation.find_by(slug: :apf), user: user, uid: "21922484") }
  let!(:apf_response) do
    [{ "BasicInformtation" => { "APFNum" => "21922484", "FirstName" => "Victor", "LastName" => "Rudolfsson", "DateOfBirth" => "1990-12-22T00:00:00.000Z", "Gender" => "M" }, "JumpRecords" => nil, "WaiverInfo" => nil, "Qualifications" => [{ "Qualification" => "Certificate A", "IssueDate" => "2019-12-24T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "15928" }, { "Qualification" => "Certificate B", "IssueDate" => "2020-07-02T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "10060" }, { "Qualification" => "Certificate C", "IssueDate" => "2020-07-02T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "8693" }, { "Qualification" => "Certificate D", "IssueDate" => "2020-10-06T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "6822" }, { "Qualification" => "Certificate E", "IssueDate" => "2021-05-29T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "3997" }, { "Qualification" => "Display General", "IssueDate" => "2020-12-14T00:00:00.000Z", "ExpiryDate" => "2021-12-31T00:00:00.000Z", "SerialNumber" => "6010" }, { "Qualification" => "Freefly Crest HU", "IssueDate" => "2020-10-06T00:00:00.000Z", "ExpiryDate" => nil, "SerialNumber" => "995" }, { "Qualification" => "Sporting Licence", "IssueDate" => "2020-03-03T00:00:00.000Z", "ExpiryDate" => "2022-06-30T00:00:00.000Z", "SerialNumber" => "0" }], "MembershipInfo" => [{ "Name" => "Financial Membership", "Status" => "Active", "ExpiryDate" => "2022-06-30T00:00:00.000Z" }], "BalanceFee" => nil, "ColorCode" => [{ "Code" => "RED", "Message" => "Member has not accepted current club waiver" }] }]
  end

  describe "syncing federation qualifications" do
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
      to_return(body: apf_response.to_json, headers: { "Content-Type" => "application/json" })
      Federations::ApfSync.run(user_federation: user_federation)
    end

    it { expect(user.reload.licenses.includes(:federation).find_by(federation: { slug: :apf }).name).to eq "Certificate E" }
    it { expect(user.reload.qualifications.reload.find_by(name: "Freefly Crest HU")).not_to be nil }
    it { expect(user.reload.qualifications.find_by(name: "Display General")).not_to be nil }
    it { expect(dropzone_user.reload.license.id).not_to be nil }
    it { expect(dropzone_user.reload.license.id).to eq user.reload.licenses.includes(:federation).find_by(federation: { slug: :apf }).id }
  end

  describe "syncing failed" do
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
      to_return(body: nil, headers: { "Content-Type" => "application/json" })
      Federations::ApfSync.run(user_federation: user_federation)
    end

    it { expect(dropzone_user.reload.license).to be nil }
  end
end
