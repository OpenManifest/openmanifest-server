# frozen_string_literal: true

module Types::Manifest
  class Slot < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::SellableItem

    def title
      "Slot on Load #{object.load.load_number}"
    end
    timestamp_fields
    field :id, GraphQL::Types::ID, null: false
    field :body_mass_kg, Integer, null: false
    # Send it back with updateSlot: a slot changed by somebody else in the meantime is refused (CONFLICT)
    field :lock_version, Int, null: false
    def body_mass_kg
      object.body_mass_kg.to_i
    end
    field :group_number, Integer, null: false
    field :prepaid, Boolean, null: false, description: "Paid for already: nothing is taken from the member's wallet"

    async_field :membership, Types::Users::Membership, null: true
    field :cost_cents, Int, null: false
    def cost_cents
      preload(:ticket_type, :extras).cost_cents
    end

    async_field :ticket_type, Types::Operator::Ticket, null: true
    async_field :load, Types::Manifest::Load, null: false
    async_field :load_vehicle, Types::Manifest::LoadVehicle, null: true
    async_field :destination, Types::Operator::Destination, null: true
    field :equipment, [Types::Equipment::Equipment], null: false, description: "The items the slot uses"
    def equipment
      dataloader.with(::Sources::AssociationLoader, [:equipment]).load(object).equipment
    end
    async_field :activity_type, Types::Meta::ActivityType, null: true
    async_field :order, Types::Payments::Order, null: true
    field :wing_loading, Float, null: true
    def wing_loading
      dataloader.with(::Sources::AssociationLoader, [{ equipment: :kind }, :guest_slots]).load(object)
      object.wing_loading
    end

    async_field :guest, Types::Manifest::Guest, null: true, description: "Who rides in this slot, when it is a guest's"
    async_field :escort_slot, Types::Manifest::Slot, null: true, description: "The slot of the escort, when this is a guest's"
    field :guest_slots, [Types::Manifest::Slot], null: false, description: "The slots of the guests who ride with this slot's member, the escort"
    def guest_slots
      dataloader.with(::Sources::AssociationLoader, [{ guest_slots: :guest }]).load(object).guest_slots.sort_by(&:id)
    end

    field :extras, [Types::Operator::Tickets::Addon], null: true
    def extras
      preload(:extras).extras
    end

    private

    # Loads the associations of this slot together with those of the other slots of the response, and gives the slot back
    def preload(*associations)
      dataloader.with(::Sources::AssociationLoader, associations).load(object)
    end
  end
end
