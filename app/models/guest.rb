# frozen_string_literal: true

# == Schema Information
#
# Table name: guests
#
#  id          :bigint           not null, primary key
#  name        :string
#  body_mass_kg :float
#  email       :string
#  phone       :string
#  date_of_birth :date
#  emergency_contact :string
#  operator_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Somebody who rides along with an escort, with the personal fields of a booking participant
class Guest < ApplicationRecord
  belongs_to :operator
end
