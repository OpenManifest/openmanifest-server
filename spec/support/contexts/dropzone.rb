# frozen_string_literal: true

RSpec.shared_context "dropzone", shared_context: :metadata do
  let!(:dropzone) { create(:dropzone, credits: 50, state: "public") }
  let!(:plane) { create(:plane, dropzone: dropzone, max_slots: 16) }
  let!(:staff_user) { create(:user, moderation_role: :user) }
  let!(:user) { create(:user, moderation_role: :user) }
  let!(:fun_jumper) { create(:dropzone_user, dropzone: dropzone, user: user, user_role: dropzone.user_roles.default_licensed) }
  let!(:instructor) { create(:dropzone_user, dropzone: dropzone, user: staff_user, user_role: dropzone.user_roles.find_by(name: :aff_instructor)) }
end
