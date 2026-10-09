# frozen_string_literal: true

require "rails_helper"

RSpec.describe DropzoneUser do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:dropzone) { create(:dropzone) }
  let!(:dropzone_users) { create_list(:dropzone_user, 5, dropzone: dropzone) }

  before do
    dropzone_users.shuffle.take(2).each(&:discard)
  end

  it { expect(dropzone.dropzone_users.count).to eq 3 }

  describe "uniqueness in the database (BUG-050)" do
    it "refuses a second membership of the same user at a dropzone, validations or not" do
      dropzone = create(:dropzone)
      member = create(:dropzone_user, dropzone: dropzone)

      duplicate = DropzoneUser.new(dropzone: dropzone, user: member.user, user_role: member.user_role)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
