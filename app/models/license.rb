# frozen_string_literal: true

# == Schema Information
#
# Table name: licenses
#
#  id            :integer          not null, primary key
#  name          :string
#  federation_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class License < ApplicationRecord
  belongs_to :federation
  has_many :users
end
