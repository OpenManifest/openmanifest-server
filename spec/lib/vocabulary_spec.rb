# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/vocabulary")
require Rails.root.join("lib/vocabulary/tree")

# P7.1: the rename map and the functions behind bin/check-vocabulary and bin/rename-vocabulary. The client has the same
# cases in scripts/__tests__/vocabulary.test.ts for scripts/lib/vocabulary.js.
RSpec.describe Vocabulary do
  let(:entries) { described_class.entries }

  def rewrite(text, groups = nil)
    described_class.rewrite(text, groups ? described_class.entries(groups) : entries)
  end

  describe ".rewrite" do
    {
      "dropzone" => "operator",
      "Dropzone" => "Operator",
      "dropzones" => "operators",
      "dropzoneId" => "operatorId",
      "dropzone_id" => "operator_id",
      "currentDropzoneId" => "currentOperatorId",
      "DropzoneUser" => "Membership",
      "dropzoneUsers" => "memberships",
      "dropzone_users" => "memberships",
      "DROPZONE_USER" => "MEMBERSHIP",
      "updateDropzoneUser" => "updateMembership",
      "DropzoneUserEssentials" => "MembershipEssentials",
      "exit_weight" => "body_mass_kg",
      "exitWeight" => "bodyMassKg",
      "ExitWeight" => "BodyMassKg",
      "EXIT_WEIGHT" => "BODY_MASS_KG",
      "planes" => "vehicles",
      "federations" => "certification_bodies",
      "Federations" => "CertificationBodies",
      "federationId" => "certificationBodyId",
      "createPlane" => "createVehicle",
      "PlaneChip" => "VehicleChip",
      "actAsDZSO" => "actAsDutyOfficer",
      "dropzone-user-card" => "membership-card",
      "my-dropzone" => "my-operator",
    }.each do |input, expected|
      it "turns #{input} into #{expected}" do
        expect(rewrite(input)).to eq(expected)
      end
    end

    it "leaves words that merely contain an old word alone" do
      expect(rewrite("airplane bigrig planet riggers dropzoned")).to eq("airplane bigrig planet riggers dropzoned")
    end

    it "rewrites identifiers inside code and keeps everything else" do
      source = "  belongs_to :dropzone, class_name: 'Dropzone' # the dropzone_user's DropzoneUser\n"

      expect(rewrite(source, "tenant")).to eq("  belongs_to :operator, class_name: 'Operator' # the membership's Membership\n")
    end

    it "applies only the requested group" do
      expect(rewrite("dropzone plane", "tenant")).to eq("operator plane")
      expect(rewrite("dropzone plane", "vehicle")).to eq("dropzone vehicle")
    end

    it "prefers the longer phrase" do
      expect(rewrite("user_federation_qualification user_federation federation", "certifications")).to eq(
        "user_qualification user_certification certification_body"
      )
    end

    it "is idempotent: new names contain no old term" do
      entries.each do |entry|
        renamed = rewrite(entry.old)
        expect(rewrite(renamed)).to eq(renamed), "#{entry.old} -> #{renamed} -> #{rewrite(renamed)}"
      end
    end
  end

  describe ".scan" do
    it "counts old terms per entry across identifiers" do
      counts = described_class.scan("Dropzone dropzoneId dropzone_users airplane DropzoneUser plane", entries)

      expect(counts).to include("dropzone" => 2, "dropzone_user" => 2, "plane" => 1)
    end
  end

  describe ".allowed?" do
    let(:allow) { %w(docs/** app/**/skydiving/** db/migrate/** CHANGELOG.md) }

    it "matches the allow globs" do
      expect(described_class.allowed?("docs/reference/README.md", allow)).to be(true)
      expect(described_class.allowed?("app/skydiving/jump.rb", allow)).to be(true)
      expect(described_class.allowed?("app/models/skydiving/jump.rb", allow)).to be(true)
      expect(described_class.allowed?("db/migrate/20240101_x.rb", allow)).to be(true)
      expect(described_class.allowed?("CHANGELOG.md", allow)).to be(true)
    end

    it "does not match other paths" do
      expect(described_class.allowed?("app/models/dropzone.rb", allow)).to be(false)
      expect(described_class.allowed?("lib/CHANGELOG.md", allow)).to be(false)
    end
  end

  describe "config/vocabulary.yml" do
    it "has no entry for Load, which keeps its name (D5)" do
      expect(entries.map(&:old)).not_to include("load", "load_number", "load_date")
    end

    it "allows the skydiving paths, migrations and docs" do
      allow_list = described_class.config.fetch("allow")

      expect(allow_list).to include("config/industries/skydiving/**", "db/migrate/**", "docs/**", "CHANGELOG.md")
    end
  end
end
