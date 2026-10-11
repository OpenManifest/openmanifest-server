# frozen_string_literal: true

require "rails_helper"

# BUG-091: nil and unknown keys used to be dropped, which shifted every following result onto the wrong key.
RSpec.describe Sources::Model do
  let(:dropzone) { create(:dropzone) }
  let!(:first_user) { create(:dropzone_user, dropzone: dropzone) }
  let!(:second_user) { create(:dropzone_user, dropzone: dropzone) }

  def fetch(*ids)
    GraphQL::Dataloader.with_dataloading do |dataloader|
      dataloader.with(described_class, DropzoneUser).load_all(ids)
    end
  end

  it "returns one result per key in the order of the keys" do
    expect(fetch(second_user.id, first_user.id)).to eq([second_user, first_user])
  end

  it "keeps the position of a nil key" do
    expect(fetch(first_user.id, nil, second_user.id)).to eq([first_user, nil, second_user])
  end

  it "returns nil for a key without a record" do
    expect(fetch(first_user.id, 0, second_user.id)).to eq([first_user, nil, second_user])
  end
end
