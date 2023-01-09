# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#
class Permission < ApplicationRecord
  include Config::Yaml::Permissions
  scope :without_acting, -> { where("name NOT LIKE (?)", "actAs%") }
  scope :only_acting, -> { where("name LIKE (?)", "actAs%") }

  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :user_role_permissions, dependent: :destroy
  has_many :user_permissions, dependent: :destroy
end
