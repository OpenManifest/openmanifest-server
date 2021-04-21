# frozen_string_literal: true

class ChecklistValue < ApplicationRecord
  belongs_to :checklist_item
  belongs_to :created_by
  belongs_to :updated_by
end
