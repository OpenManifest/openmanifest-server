# frozen_string_literal: true

class Resolvers::Operator::AvailableRigs < Resolvers::Base
  description "Get user rigs that have been inspected and marked as OK + operator rigs"
  type [Types::Equipment::Rig], null: true
  argument  :membership, Integer, required: true,
                                  description: "Operator User to get rigs for",
                                  prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
  argument  :is_tandem,        Boolean, required: false
  argument  :load_id,          Integer, required: false,
                                        description: "Filter out rigs already occupied for a load"
  def resolve(
    membership: nil,
    is_tandem: nil,
    load_id: nil
  )
    authorize_record!(membership)
    return membership.operator.tandem_rigs if is_tandem

    Rig.available_for(membership).where.not(
      id: membership.operator.rigs.occupied
    )
  end
end
