# frozen_string_literal: true

class Resolvers::Meta::ActivityTypes < Resolvers::Base
  description "Get all jump types"
  type [Types::Meta::ActivityType], null: false
  argument :memberships, [Int], required: false,
                                prepare: -> (value, ctx) { Membership.where(id: value) }

  def resolve(memberships: nil)
    if memberships
      ActivityType.allowed_for(memberships)
    else
      ActivityType.order(name: :asc)
    end
  end

  def authenticated?
    true
  end
end
