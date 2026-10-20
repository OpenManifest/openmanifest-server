# frozen_string_literal: true

# == Schema Information
#
# Table name: certification_bodies
#
#  id                    :bigint           not null, primary key
#  industry              :string
#  name                  :string
#  slug                  :string
#  verification_provider :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# An organisation that certifies people (a federation, a training agency): it issues levels that rank against each other
# and qualifications. Operators accept one or several; a body may have no levels (qualifications only).
class CertificationBody < ApplicationRecord
  include Config::Yaml::CertificationBodies

  # Verification providers by name: they check a member's number against the body's own records
  PROVIDERS = { "apf" => "Certifications::Providers::Apf" }.freeze

  has_many :certification_levels, -> { order(:rank, :id) }, inverse_of: :certification_body, dependent: :restrict_with_error
  has_many :qualifications, dependent: :restrict_with_error
  has_many :user_certifications, dependent: :restrict_with_error
  has_many :users, through: :user_certifications
  has_many :operator_certification_bodies, dependent: :destroy
  has_many :operators, -> { kept }, through: :operator_certification_bodies

  scope :for_industry, ->(industry) { where(industry: industry) }

  validates_presence_of :slug, on: :create, message: "must be defined"
  validates_presence_of :name, on: :create, message: "must be defined"
  validates :verification_provider, inclusion: { in: PROVIDERS.keys }, allow_nil: true

  # @return [Class, nil] the verification provider of the body, nil when staff verify by hand
  def provider
    PROVIDERS[verification_provider]&.constantize
  end
end
