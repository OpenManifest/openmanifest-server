# frozen_string_literal: true

module Types::Manifest
  class Load < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_completed, Boolean, null: true
    field :weight, Integer, null: false
    def weight
      preload(:slots, { pilot: :user })
      pilot_weight = object.pilot.try(:user).try(:body_mass_kg) || 0
      pilot_weight + (object.slots.map(&:body_mass_kg).compact_blank.sum || 0)
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

    async_field :pilot, Types::Users::Membership, null: true
    field :vehicle, Types::Operator::Vehicle, null: false, description: "The first vehicle that carries participants"
    def vehicle
      preload(load_vehicles: :vehicle).vehicle
    end

    field :vehicles, [Types::Manifest::LoadVehicle], null: false, description: "The vehicles of the load, those that carry first"
    def vehicles
      preload(load_vehicles: :vehicle).load_vehicles.sort_by { |load_vehicle| [load_vehicle.position, load_vehicle.id] }
    end

    async_field :load_master, Types::Users::Membership, null: true
    async_field :state, Types::Manifest::LoadState, null: false
    async_field :gca, Types::Users::Membership, null: true
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
