# frozen_string_literal: true

# == Schema Information
#
# Table name: federations
#
#  id         :integer          not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Federation < ApplicationRecord
  has_many :licenses
  has_many :users, through: :licenses

  validates_presence_of :slug, on: :create, message: "must be defined"
  validates_presence_of :name, on: :create, message: "must be defined"
end
