# frozen_string_literal: true

module Types::Manifest
  class Load < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    lookahead do |query|
      query = query.includes(slots: :dropzone_user)  if selects?(:slots)
      query = query.includes(:gca)                   if selects?(:gca)
      query = query.includes(:load_master)           if selects?(:load_master)
      query = query.includes(:pilot)                 if selects?(:pilot)
      query = query.includes(:plane)                 if selects?(:plane)
      query
    end

    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_landed, Boolean, null: true
    field :weight, Integer, null: false
    def weight
      preload(:slots, { pilot: :user })
      pilot_weight = object.pilot.try(:user).try(:exit_weight) || 0
      pilot_weight + (object.slots.map(&:exit_weight).compact_blank.sum || 0)
    end

    # Send it back with updateLoad: a load changed by somebody else in the meantime is refused (CONFLICT)
    field :lock_version, Int, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :available_slots, Int, null: false
    def available_slots
      preload(:plane).available_slots
    end

    field :occupied_slots, Int, null: false
    def occupied_slots
      preload(:plane).occupied_slots
    end

    field :max_slots, Int, null: false
    field :is_open, Boolean, null: false
    def is_open
      object.state == "open"
    end
    field :slots, [Types::Manifest::Slot], null: true
    def slots
      # This exludes tandem passengers as they are part
      # of the tandem masters slot
      # In memory: the slots of every load of a list are loaded at once (BUG-049)
      preload(:slots).slots.reject { |slot| slot.dropzone_user_id.nil? }
    end

    async_field :pilot, Types::Users::DropzoneUser, null: true
    async_field :plane, Types::Dropzone::Aircraft, null: false
    async_field :load_master, Types::Users::DropzoneUser, null: true
    async_field :state, Types::Manifest::LoadState, null: false
    async_field :gca, Types::Users::DropzoneUser, null: true
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
