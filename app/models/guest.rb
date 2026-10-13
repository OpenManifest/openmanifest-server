# frozen_string_literal: true

# == Schema Information
#
# Table name: guests
#
#  id          :bigint           not null, primary key
#  name        :string
#  body_mass_kg :float
#  operator_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Guest < ApplicationRecord
  belongs_to :operator
end
