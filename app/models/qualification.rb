# frozen_string_literal: true

# == Schema Information
#
# Table name: qualifications
#
#  id                    :bigint           not null, primary key
#  name                  :string
#  slug                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  certification_body_id :bigint           not null
#
# Something a body certifies that is not a rank: a rating, a licence, a medical. Holders may have an expiry date.
class Qualification < ApplicationRecord
  belongs_to :certification_body
  has_many :user_qualifications, dependent: :restrict_with_error
end
