# frozen_string_literal: true

# == Schema Information
#
# Table name: federations
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Federation < ApplicationRecord
  has_many :licenses
  has_many :users, through: :licenses
  has_many :dropzones, -> { kept }

  validates_presence_of :slug, on: :create, message: "must be defined"
  validates_presence_of :name, on: :create, message: "must be defined"

  class << self
    # Parse YAML config for default configuration
    #
    # @return [Hash<Symbol, Array<String>>]
    def config
      @config ||= YAML.safe_load(
        File.read("config/seed/global.yml"),
        symbolize_names: true
      )[:federations]
    end
  end
end
