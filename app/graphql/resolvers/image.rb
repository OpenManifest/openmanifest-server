# frozen_string_literal: true

class Resolvers::Image < Resolvers::Base
  type String, null: true
  description "Get Base64 images via GraphQL"
  argument :id, Int, required: true
  def resolve(id: nil)
    blob = ActiveStorage::Blod.find(id)
    blob.download
  end
end
