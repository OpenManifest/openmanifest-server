# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_type_extras
#
#  id             :integer          not null, primary key
#  ticket_type_id :integer          not null
#  extra_id       :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class TicketTypeExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
