# frozen_string_literal: true

class Resolvers::Users::Membership < Resolvers::Base
  type Types::Users::Membership, null: true
  description "Get a specific user at an operator"

  argument :id, ID, required: true

  def resolve(id: nil)
    return nil unless id
    query = Membership.all

    membership = query.find_by(id: id)
    return nil unless membership

    # Your own membership is always readable; other members need readUser at their operator
    own = current_user && membership.user_id == current_user.id
    authorize_record!(membership, own ? nil : :readUser)
    membership
  end
end
