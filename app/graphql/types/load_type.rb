module Types
  class LoadType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_landed, Boolean, null: true
    field :pilot_id, Int, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :slots, [Types::SlotType], null: true
    field :plane, Types::PlaneType, null: false
    field :load_master, Types::UserType, null: true
    field :gca, Types::UserType, null: true

    field :is_ready, Boolean, null: false
    def is_ready
      object.ready?
    end

    field :is_open, Boolean, null: false
    def is_open
      object.dispatch_at < DateTime.now && (object.slots.count < object.plane.max_slots)
    end
  end
end