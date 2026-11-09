# frozen_string_literal: true

class Resolvers::Meta::CertificationLevels < Resolvers::Base
  description "Get all certification levels of a certification body, lowest rank first"
  type [Types::Meta::CertificationLevel], null: false
  argument :certification_body_id, Int, required: false

  def resolve(certification_body_id: nil)
    query = CertificationLevel.all
    query = query.where(certification_body_id: certification_body_id) if certification_body_id

    query.order(:rank, :name)
  end
end
