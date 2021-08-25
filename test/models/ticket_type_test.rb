# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_types
#
#  id                     :bigint           not null, primary key
#  cost                   :float
#  currency               :string
#  name                   :string
#  dropzone_id            :bigint           not null
#  altitude               :integer
#  allow_manifesting_self :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  is_tandem              :boolean          default(FALSE)
#  is_deleted             :boolean          default(FALSE)
#
require "test_helper"

class TicketTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
