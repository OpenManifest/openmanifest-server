# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::Global::Seeds::CertificationBodies do
  let(:apf) { CertificationBody.find_by!(slug: "apf") }

  it "seeds the bodies of the catalogue with their provider, industry, ranks and equivalence keys" do
    expect(apf).to have_attributes(name: "APF", industry: "skydiving", verification_provider: "apf")
    expect(apf.certification_levels.find_by!(name: "Certificate B")).to have_attributes(rank: 30, equivalence_key: "b")
    expect(apf.certification_levels.find_by!(name: "Certificate B").activity_types.pluck(:slug)).to include("freefly", "angle")
  end

  it "can run again: it restores what the catalogue says and adds nothing twice" do
    level = apf.certification_levels.find_by!(name: "Certificate B")
    level.update!(rank: 99)

    expect { described_class.run! }.not_to change { [CertificationBody.count, CertificationLevel.count, PermittedActivity.count] }

    expect(level.reload.rank).to eq(30)
  end
end
