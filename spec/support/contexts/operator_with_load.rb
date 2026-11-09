# frozen_string_literal: true

RSpec.shared_context "operator_with_load", shared_context: :metadata do
  include_context 'operator'
  let!(:gca) { create(:membership, operator: operator) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:load) { create(:load, vehicle: vehicle, pilot: pilot, gca: gca) }
end
