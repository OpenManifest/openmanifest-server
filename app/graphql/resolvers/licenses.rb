# frozen_string_literal: true

class Resolvers::Licenses < Resolvers::Base
  description "Get all licenses for a federation"
  type [Types::LicenseType]
  argument :federation_id, Int, required: false

  def resolve(federation_id: nil, lookahead: nil)
    query = License.all
    query = query.includes(:federation)                 if lookahead.selects?(:federation)
    query = query.where(federation_id: federation_id)   if federation_id

    query.order(name: :asc)
  end
end
