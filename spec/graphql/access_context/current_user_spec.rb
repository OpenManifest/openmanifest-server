# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccessContext::CurrentUser do
  let(:dropzone_a) { create(:dropzone) }
  let(:dropzone_b) { create(:dropzone) }
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let!(:member_a) { create(:dropzone_user, dropzone: dropzone_a, user: user_a, user_role: dropzone_a.user_roles.find_by(name: "fun_jumper")) }
  let!(:member_b) { create(:dropzone_user, dropzone: dropzone_b, user: user_b, user_role: dropzone_b.user_roles.find_by(name: "fun_jumper")) }

  describe "BUG-001: one access context per request" do
    it "gives every caller its own object" do
      first = described_class.for(user_a)
      second = described_class.for(user_b)

      expect(first).not_to equal(second)
      expect(first.user).to eq(user_a)
      expect(second.user).to eq(user_b)
    end

    it "does not carry state from one context to the next" do
      described_class.for(user_a).at_dropzone(dropzone_a)

      expect(described_class.for(user_b).dropzone).to be_nil
    end

    it "returns the membership of the dropzone it was last moved to" do
      context = described_class.for(user_a)

      expect(context.at_dropzone(dropzone_a).dropzone_user).to eq(member_a)
      # A user without a membership in B has none there, rather than the memoised one of A
      expect(context.at_dropzone(dropzone_b).dropzone_user).to be_nil
      expect(context.at_dropzone(dropzone_a).dropzone_user).to eq(member_a)
    end

    it "resolves ids as well as records" do
      context = described_class.for(user_a)

      expect(context.at_dropzone(dropzone_a.id.to_s).dropzone).to eq(dropzone_a)
      expect(context.at_dropzone(dropzone_b.id).dropzone).to eq(dropzone_b)
    end
  end
end
