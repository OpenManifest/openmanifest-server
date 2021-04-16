# frozen_string_literal: true

class ChecklistItem < ApplicationRecord
  belongs_to :checklist
  belongs_to :created_by
  belongs_to :updated_by
  has_many :checklist_values
end
