# frozen_string_literal: true

class Resolvers::Meta::JumpTypes < Resolvers::Base
  description "Get all jump types"
  type [Types::Meta::JumpType], null: false
  argument :memberships, [Int], required: false,
                                prepare: -> (value, ctx) { Membership.where(id: value) }

  def resolve(memberships: nil)
    if memberships
      JumpType.allowed_for(memberships)
    else
      JumpType.order(name: :asc)
    end
  end

  def authenticated?
    true
  end
end
