# frozen_string_literal: true

class Resolvers::Meta::CertificationBodies < Resolvers::Base
  type [Types::Meta::CertificationBody], null: false
  description "Get all available certification bodies, of one industry if given"
  argument :industry, Types::IndustryEnum, required: false

  def resolve(industry: nil)
    query = CertificationBody.all
    query = query.for_industry(industry) if industry
    query.order(name: :asc)
  end
end
