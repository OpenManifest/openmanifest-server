# frozen_string_literal: true

module Types
  module Input
    class LoadInput < Types::Base::Input
      argument :name, String, required: false
      argument :max_slots, Int, required: false
      argument :load_date, GraphQL::Types::ISO8601Date, required: false,
                                                        description: "The day the load is for (create only); today by default, and not a day that has gone"
      argument :pilot, ID, required: false,
                           prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
      argument :dispatch_at, GraphQL::Types::ISO8601DateTime, required: false,
                                                              prepare: -> (value, ctx) { value ? value.to_datetime : nil }
      argument :vehicles, [Types::Input::LoadVehicleInput], required: false,
                                                            prepare: -> (value, ctx) {
                                                              value.map do |entry|
                                                                { vehicle: ::Vehicle.find_by(id: entry[:vehicle_id]), role: entry[:role] }
                                                              end
                                                            },
                                                            description: "The vehicles of the load and their roles; they replace the load's. One that carries is needed"
      argument :vehicle, ID, required: false,
                             prepare: -> (value, ctx) { ::Vehicle.find_by(id: value) }
      argument :gca, ID, required: false,
                         prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
      argument :load_master, ID, required: false,
                                 prepare: -> (value, ctx) { ::Membership.find_by(id: value) }
      argument :crew, [Types::Input::LoadCrewInput], required: false,
                                                     prepare: -> (value, ctx) {
                                                       value.map do |entry|
                                                         {
                                                           crew_role: ::CrewRole.kept.find_by(id: entry[:crew_role_id]),
                                                           membership: ::Membership.find_by(id: entry[:membership_id]),
                                                           load_vehicle: (::LoadVehicle.find_by(id: entry[:load_vehicle_id]) if entry[:load_vehicle_id]),
                                                           vehicle: (::Vehicle.find_by(id: entry[:vehicle_id]) if entry[:vehicle_id]),
                                                         }
                                                       end
                                                     },
                                                     description: "Who fills each crew role (and for which vehicle); they replace the load's crew"
      argument :destination_ids, [Int], required: false,
                                        description: "The places the load visits, in order (operators with per-load destinations)"
      argument :state, Types::Manifest::LoadState, required: false
      argument :lock_version, Int, required: false,
                                   description: "The lockVersion of the load as the client last saw it; an older one is refused with CONFLICT"
    end
  end
end
