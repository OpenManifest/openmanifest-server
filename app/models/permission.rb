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
  scope :without_acting, -> { where("name NOT LIKE (?)", "actAs%") }
  scope :only_acting, -> { where("name LIKE (?)", "actAs%") }

  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :user_role_permissions, dependent: :destroy
  has_many :user_permissions, dependent: :destroy

  class << self
    def default_acting
      @default_acting ||= config[:acting].map(&:to_sym)
    end

    def default_crud
      @default_crud ||= config[:crud].values.flatten.uniq.map(&:to_sym)
    end

    def slugs
      Permission.default_acting + Permission.default_crud
    end

    def config
      @config ||= YAML.safe_load(
        File.read('config/seed/access.yml'),
        symbolize_names: true,
        aliases: true
      )[:permissions]
    end
  end
end
