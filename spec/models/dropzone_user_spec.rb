# frozen_string_literal: true

require "rails_helper"

RSpec.describe DropzoneUser, type: :model do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:dropzone) { create(:dropzone) }
  let!(:dropzone_users) { create_list(:dropzone_user, 5, dropzone: dropzone) }

  before do
    dropzone_users.shuffle.take(2).each(&:discard)
  end

  it { expect(dropzone.dropzone_users.count).to eq 3 }
end
