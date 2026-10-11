# frozen_string_literal: true

RSpec.shared_context "operator", shared_context: :metadata do
  let!(:operator) { create(:operator, credits: 50, state: "public") }
  let!(:plane) { create(:plane, operator: operator, max_slots: 16) }
  let!(:staff_user) { create(:user, moderation_role: :user) }
  let!(:user) { create(:user, moderation_role: :user) }
  let!(:fun_jumper) { create(:membership, operator: operator, user: user, user_role: operator.user_roles.default_licensed) }
  let!(:instructor) { create(:membership, operator: operator, user: staff_user, user_role: operator.user_roles.find_by(name: :aff_instructor)) }
end
