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
class TicketTypeExtra < ApplicationRecord
  belongs_to :ticket_type
  belongs_to :extra
end
