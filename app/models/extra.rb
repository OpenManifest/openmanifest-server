# frozen_string_literal: true

# == Schema Information
#
# Table name: extras
#
#  id          :bigint           not null, primary key
#  name        :string
#  operator_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Extra < ApplicationRecord
  include MoneyAttributes

  money :cost
  include Discard::Model

  belongs_to :operator

  has_many :ticket_type_extras
  has_many :ticket_types, through: :ticket_type_extras
end
