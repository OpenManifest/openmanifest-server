module Types
  class DropzoneType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :federation, FederationType, null: false
    field :primary_color, String, null: true
    field :secondary_color, String, null: true
    field :current_user, Types::DropzoneUserType, null: false
    def current_user
      DropzoneUser.where(
        dropzone: object,
        user: context[:current_resource]
      )
    end

    field :is_public, Boolean, null: false
    def is_public
      !!object.is_public
    end

    field :ticket_types, [Types::TicketTypeType], null: false
    field :planes, [Types::PlaneType], null: false
    field :loads, Types::LoadType.connection_type, null: false do
      argument :earliest_timestamp, Int, required: false
    end
    field :current_user_role, String, null: false
    def current_user_role
      if object.dropzone_users.where(user: context[:current_resource]).exists?
        object.dropzone_users.find_by(user: context[:current_resource]).role
      end
      "visitor"
    end

    def loads(earliest_timestamp: nil)
      loads = object.loads
      loads = loads.where("created_at > ?", earliest_timestamp) unless earliest_timestamp.nil?
      loads.order(created_at: :desc)
    end

    field :banner_id, Int, null: true
    def banner_id
      if object.banner.attached?
        object.banner.blob.id
      end
    end

    field :banner, String, null: true
    def banner
      if object.banner.attached?
        "data:%s;base64,%s" % [object.banner.blob.content_type, Base64.strict_encode64(object.banner.blob.download)]
      end
    end
  end
end