# frozen_string_literal: true

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
