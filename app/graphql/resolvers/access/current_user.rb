# frozen_string_literal: true

class Resolvers::Access::CurrentUser < Resolvers::Base
  type Types::Users::User, null: true
  description "Currently authenticated user"

  def resolve(lookahead: nil)
    return nil unless context[:current_resource]
    query = apply_lookaheads(lookahead, User)

    query.find_by(id: context[:current_resource])
  end
end
