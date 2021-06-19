# == Schema Information
#
# Table name: notifications
#
#  id                :integer          not null, primary key
#  message           :string
#  received_by_id    :integer          not null
#  sent_by_id        :integer
#  resource_type     :string
#  resource_id       :integer
#  notification_type :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_seen           :boolean          default(FALSE)
#
require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
