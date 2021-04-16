# frozen_string_literal: true

class Checklist < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  has_many :checklist_items
end
