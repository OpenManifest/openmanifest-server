# frozen_string_literal: true

require "rails_helper"

RSpec.describe DropzoneUser, type: :model do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:dropzones) { create_list(:dropzone_with_loads, 6, federation: federation) }

  before do
    dropzones.shuffle.take(3).each(&:discard)
  end

  it { expect(Dropzone.kept.count).to eq 3 }
  it { expect(Dropzone.count).to eq 6 }
  it { expect(federation.dropzones.count).to eq 3 }
end
