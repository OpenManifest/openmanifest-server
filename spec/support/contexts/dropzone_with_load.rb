# frozen_string_literal: true

RSpec.shared_context "dropzone_with_load", shared_context: :metadata do
  include_context 'dropzone'
  let!(:gca) { create(:dropzone_user, dropzone: dropzone) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:load) { create(:load, plane: plane, pilot: pilot, gca: gca) }
end
