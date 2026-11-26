# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership do
  let!(:certification_body) { CertificationBody.find_by(slug: :apf) }
  let!(:operators) { create_list(:operator_with_loads, 6, certification_bodies: [certification_body]) }

  before do
    operators.shuffle.take(3).each(&:discard)
  end

  it { expect(Operator.kept.count).to eq 3 }
  it { expect(Operator.count).to eq 6 }
  it { expect(certification_body.operators.count).to eq 3 }
end
