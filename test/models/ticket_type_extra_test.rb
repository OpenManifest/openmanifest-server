# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_type_extras
#
#  id             :bigint           not null, primary key
#  ticket_type_id :bigint           not null
#  extra_id       :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class TicketTypeExtraTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
