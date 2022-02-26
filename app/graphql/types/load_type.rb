# frozen_string_literal: true

module Types
  class LoadType < Types::BaseObject
    implements Types::AnyResourceType

    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_landed, Boolean, null: true
    field :pilot, Types::DropzoneUserType, null: true
    field :weight, Integer, null: false
    def weight
      pilot_weight = object.pilot.try(:user).try(:exit_weight) || 0
      pilot_weight + (object.slots.map(&:exit_weight).reject(&:blank?).reduce(:+) || 0)
    end

    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :available_slots, Int, null: false
    field :occupied_slots, Int, null: false

    field :max_slots, Int, null: false
    field :is_open, Boolean, null: false
    field :slots, [Types::SlotType], null: true
    def slots
      # This exludes tandem passengers as they are part
      # of the tandem masters slot
      object.slots.where.not(dropzone_user: nil)
    end

    field :plane, Types::PlaneType, null: false
    field :load_master, Types::DropzoneUserType, null: true
    field :load_number, Int, null: false
    field :state, Types::LoadStateType, null: false
    field :gca, Types::DropzoneUserType, null: true


    field :is_ready, Boolean, null: false
    def is_ready
      object.ready?
    end


    field :is_full, Boolean, null: false
    def is_full
      !!((object.dispatch_at && object.dispatch_at < DateTime.now) && (object.slots.count >= object.max_slots))
    end
  end
end
