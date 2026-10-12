# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:operators) { create_list(:operator_with_loads, 6, federation: federation) }

  before do
    operators.shuffle.take(3).each(&:discard)
  end

  it { expect(Operator.kept.count).to eq 3 }
  it { expect(Operator.count).to eq 6 }
  it { expect(federation.operators.count).to eq 3 }
end
