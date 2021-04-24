# frozen_string_literal: true

module Types
  class LoadType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :dispatch_at, Int, null: true
    field :name, String, null: true
    field :has_landed, Boolean, null: true
    field :pilot, Types::DropzoneUserType, null: true
    def pilot
      if object.pilot
        object.pilot.dropzone_users.find_by(dropzone_id: object.plane.dropzone_id)
      end
    end

    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :max_slots, Int, null: false
    field :is_open, Boolean, null: false
    field :slots, [Types::SlotType], null: true
    field :plane, Types::PlaneType, null: false
    field :load_master, Types::DropzoneUserType, null: true
    field :load_number, Int, null: false
    def load_number
      load_index = object.plane.dropzone.loads.where(
        "created_at > ?",
        DateTime.now.beginning_of_day
      ).order(created_at: :asc).find_index do |load|
        load.id == object.id
      end

      (load_index || 0) + 1
    end

    def load_master
      if object.load_master
        object.load_master.dropzone_users.find_by(dropzone_id: object.plane.dropzone_id)
      end
    end

    field :gca, Types::DropzoneUserType, null: true
    def gca
      if object.gca
        object.gca.dropzone_users.find_by(dropzone_id: object.plane.dropzone_id)
      end
    end


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
