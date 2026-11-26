# frozen_string_literal: true

class Resolvers::Meta::Qualifications < Resolvers::Base
  description "Get all qualifications of a certification body"
  type [Types::Meta::Qualification], null: false
  argument :certification_body_id, Int, required: false

  def resolve(certification_body_id: nil)
    query = Qualification.all
    query = query.where(certification_body_id: certification_body_id) if certification_body_id

    query.order(:name)
  end
end
