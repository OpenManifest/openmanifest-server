# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership do
  let!(:federation) { Federation.find_by(slug: :apf) }
  let!(:operator) { create(:operator) }
  let!(:memberships) { create_list(:membership, 5, operator: operator) }

  before do
    memberships.shuffle.take(2).each(&:discard)
  end

  it { expect(operator.memberships.count).to eq 3 }

  describe "uniqueness in the database (BUG-050)" do
    it "refuses a second membership of the same user at an operator, validations or not" do
      operator = create(:operator)
      member = create(:membership, operator: operator)

      duplicate = Membership.new(operator: operator, user: member.user, user_role: member.user_role)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
