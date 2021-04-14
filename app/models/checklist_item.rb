class ChecklistItem < ApplicationRecord
  belongs_to :checklist
  belongs_to :created_by
  belongs_to :updated_by
end
