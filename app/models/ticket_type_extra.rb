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
class TicketTypeExtra < ApplicationRecord
  belongs_to :ticket_type
  belongs_to :extra
end
