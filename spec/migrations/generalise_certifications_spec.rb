# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012140000_generalise_certifications")

# P7.13: federations and licences become certification bodies and levels. The example goes back to the old tables inside
# its transaction, writes old rows, migrates forward and reads the new ones.
RSpec.describe GeneraliseCertifications do
  let(:connection) { ActiveRecord::Base.connection }
  let(:operator) { create(:operator, lat: nil, lng: nil) }
  let(:user) { create(:user) }

  def quietly(&block) = ActiveRecord::Migration.suppress_messages(&block)

  def reset_models
    [Operator, User, Membership, CertificationBody, CertificationLevel, UserCertification, UserQualification, Qualification, TicketType, Extra].each(&:reset_column_information)
  end

  after { reset_models }

  def sql(statement) = connection.select_value(statement)

  before do
    operator
    user
  end

  def old_schema
    quietly { described_class.new.migrate(:down) }
    reset_models
  end

  it "goes back to federations and licences, with the operator's first body and the setting's old name" do
    old_schema

    expect(connection.table_exists?(:federations)).to be true
    expect(connection.table_exists?(:certification_bodies)).to be false
    expect(sql("SELECT COUNT(*) FROM licenses")).to be > 0
    expect(sql("SELECT federation_id FROM operators WHERE id = #{operator.id}")).to eq(sql("SELECT id FROM federations WHERE slug = 'apf'"))
  end

  it "ranks the levels of each body in their order and keeps what the operator and the user held" do
    old_schema
    federation_id = sql("SELECT id FROM federations WHERE slug = 'apf'")
    student_id = sql("SELECT id FROM licenses WHERE name = 'Student' AND federation_id = #{federation_id}")
    connection.execute("UPDATE users SET license_id = #{student_id.to_i}, apf_number = '123' WHERE id = #{user.id}")
    connection.execute("UPDATE operators SET settings = settings || '{\"require_license\": false}'::jsonb WHERE id = #{operator.id}")

    quietly { described_class.new.migrate(:up) }
    reset_models

    body = CertificationBody.find_by!(slug: "apf")
    expect(body).to have_attributes(industry: "skydiving", verification_provider: "apf")
    expect(body.certification_levels.map(&:rank)).to eq(body.certification_levels.map(&:rank).sort.uniq)
    expect(body.certification_levels.first.rank).to eq(0)
    expect(Operator.find(operator.id).certification_bodies).to eq([body])
    expect(Operator.find(operator.id).settings).to include("require_certification" => false)
    expect(Operator.find(operator.id).settings).not_to have_key("require_license")
    expect(User.find(user.id).user_certifications.map(&:certification_level_id)).to eq([student_id.to_i])
    expect(User.column_names).not_to include("license_id", "apf_number")
  end
end
