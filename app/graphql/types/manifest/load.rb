# frozen_string_literal: true

module Types::Manifest
  class Load < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_completed, Boolean, null: true
    field :load_date, GraphQL::Types::ISO8601Date, null: false, description: "The day the load is for, in the operator's time zone; a load can be scheduled ahead"
    field :departed_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When the load left"
    field :called_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When the load was called; cleared when the call is cancelled"
    field :completed_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When the load landed; cleared when it is reopened"
    field :weight, Integer, null: false
    def weight
      preload(:slots, crew_assignments: [:crew_role, { membership: :user }])
      # The crew of a vehicle rides in it (the pilot); the crew of the load as a whole (the GCA) stays on the ground
      aboard = object.crew_assignments.select { |assignment| assignment.crew_role.vehicle_scope? }
      crew_weight = aboard.sum { |assignment| assignment.membership.user.try(:body_mass_kg) || 0 }
      crew_weight + (object.slots.map(&:body_mass_kg).compact_blank.sum || 0)
    end

    # Send it back with updateLoad: a load changed by somebody else in the meantime is refused (CONFLICT)
    field :lock_version, Int, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :available_slots, Int, null: false
    def available_slots
      preload(load_vehicles: :vehicle).available_slots
    end

    field :occupied_slots, Int, null: false
    def occupied_slots
      preload(load_vehicles: :vehicle).occupied_slots
    end

    field :max_slots, Int, null: false
    field :is_open, Boolean, null: false
    def is_open
      object.state == "open"
    end
    field :slots, [Types::Manifest::Slot], null: true
    def slots
      # This exludes tandem guests as they are part
      # of the tandem masters slot
      # In memory: the slots of every load of a list are loaded at once (BUG-049)
      preload(:slots).slots.reject { |slot| slot.membership_id.nil? }
    end

    field :destinations, [Types::Operator::Destination], null: false, description: "The places the load visits, in order"
    def destinations
      preload(load_destinations: :destination).load_destinations.sort_by(&:position).map(&:destination)
    end

    field :crew, [Types::Manifest::LoadCrewAssignment], null: false, description: "Who fills the crew roles of the load"
    def crew
      preload(crew_assignments: :crew_role).crew_assignments.sort_by { |assignment| [assignment.crew_role.position, assignment.id] }
    end

    %w(pilot gca load_master).each do |key|
      field key, Types::Users::Membership, null: true, description: "Who fills the crew role with the key #{key}"
      define_method(key) { preload(crew_assignments: [:crew_role, :membership]).crew_member(key) }
    end
    field :vehicle, Types::Operator::Vehicle, null: false, description: "The first vehicle that carries participants"
    def vehicle
      preload(load_vehicles: :vehicle).vehicle
    end

    field :vehicles, [Types::Manifest::LoadVehicle], null: false, description: "The vehicles of the load, those that carry first"
    def vehicles
      preload(load_vehicles: :vehicle).load_vehicles.sort_by { |load_vehicle| [load_vehicle.position, load_vehicle.id] }
    end

    async_field :state, Types::Manifest::LoadState, null: false
    field :load_number, Int, null: false

    field :is_ready, Boolean, null: false
    def is_ready
      object.ready?
    end

    field :is_full, Boolean, null: false
    def is_full
      !!(object.dispatch_at && object.dispatch_at < DateTime.now && (preload(:slots).slots.size >= object.max_slots))
    end

    private

    # Loads the associations of this load together with those of the other loads of the response, and gives the load back
    def preload(*associations)
      dataloader.with(::Sources::AssociationLoader, associations).load(object)
    end
  end
end
