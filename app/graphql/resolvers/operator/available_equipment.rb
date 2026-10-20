# frozen_string_literal: true

class Resolvers::Operator::AvailableEquipment < Resolvers::Base
  description "Get user equipment that have been inspected and marked as OK + operator equipment"
  type [Types::Equipment::Equipment], null: true
  argument  :membership, Integer, required: true,
                                  description: "Operator User to get equipment for",
                                  prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
  argument  :is_tandem,        Boolean, required: false, description: "Skydiving: the tandem rigs of the operator"
  argument  :kind,             String, required: false, description: "Only items of the equipment kind with this key"
  argument  :load_id,          Integer, required: false,
                                        description: "Filter out equipment already occupied for a load"
  def resolve(
    membership: nil,
    is_tandem: nil,
    kind: nil,
    load_id: nil
  )
    authorize_record!(membership)
    return Skydiving::Rigs.tandem(membership.operator) if is_tandem

    membership.available_equipment(load_id: load_id, kind: kind).where.not(id: membership.operator.equipment.occupied)
  end
end
