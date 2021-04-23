# frozen_string_literal: true

# == Schema Information
#
# Table name: checklist_items
#
#  id            :integer          not null, primary key
#  checklist_id  :integer          not null
#  created_by_id :integer          not null
#  updated_by_id :integer          not null
#  value_type    :integer
#  is_required   :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string
#  description   :text
#
class ChecklistItem < ApplicationRecord
  belongs_to :checklist
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  has_many :checklist_values, dependent: :delete_all

  enum value_type: [
    :string,
    :boolean,
    :integer,
    :date
  ]
end
