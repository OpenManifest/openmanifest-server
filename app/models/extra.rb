# frozen_string_literal: true

# == Schema Information
#
# Table name: extras
#
#  id          :bigint           not null, primary key
#  cost        :float
#  name        :string
#  dropzone_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  is_deleted  :boolean          default(FALSE)
#
class Extra < ApplicationRecord
  include Discard::Model
  has_many :ticket_type_extras, dependent: :destroy
  has_many :ticket_types, through: :ticket_type_extras
  belongs_to :dropzone

  has_many :ticket_type_extras
  has_many :ticket_types, through: :ticket_type_extras
end
