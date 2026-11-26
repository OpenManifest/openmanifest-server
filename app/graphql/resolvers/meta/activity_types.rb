# frozen_string_literal: true

class Resolvers::Meta::ActivityTypes < Resolvers::Base
  description "Get the activity types: those the members may all do, or those an operator offers"
  type [Types::Meta::ActivityType], null: false
  argument :memberships, [Int], required: false,
                                prepare: -> (value, ctx) { Membership.where(id: value) }
  argument :operator, ID, required: false,
                          description: "Only the activity types this operator offers (those its template enables)"

  def resolve(memberships: nil, operator: nil)
    types = memberships ? ActivityType.allowed_for(memberships) : ActivityType.all
    types = types.where(id: OperatorActivityType.where(operator_id: operator).select(:activity_type_id)) if operator
    types.order(name: :asc)
  end

  def authenticated?
    true
  end
end
