# frozen_string_literal: true

# == Schema Information
#
# Table name: form_templates
#
#  id            :bigint           not null, primary key
#  name          :string
#  definition    :text
#  operator_id   :bigint
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :bigint
#  updated_by_id :bigint
#
class FormTemplate < ApplicationRecord
  belongs_to :operator, optional: true
  belongs_to :created_by, class_name: "Membership", optional: true
  belongs_to :updated_by, class_name: "Membership", optional: true
end
