# frozen_string_literal: true

# == Schema Information
#
# Table name: checklists
#
#  id            :integer          not null, primary key
#  name          :string
#  created_by_id :integer          not null
#  updated_by_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Checklist < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  has_many :checklist_items, dependent: :delete_all
end
