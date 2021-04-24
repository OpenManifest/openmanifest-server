# frozen_string_literal: true

module Types
  class DropzoneType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :federation, FederationType, null: false
    field :primary_color, String, null: true
    field :secondary_color, String, null: true
    field :rig_inspection_checklist, Types::ChecklistType, null: true
    field :is_credit_system_enabled, Boolean, null: false
    def is_credit_system_enabled
      object.is_credit_system_enabled?
    end
    
    field :current_user, Types::DropzoneUserType, null: false
    def current_user
      dz_user = ::DropzoneUser.find_or_initialize_by(
        dropzone: object,
        user: context[:current_resource]
      )

      if dz_user.new_record?
        dz_user.user_role = object.user_roles.first
        dz_user.save
      end

      dz_user
    end

    field :user_roles, [Types::UserRoleType], null: false

    field :allowed_jump_types, [Types::JumpTypeType], null: false do
      argument :user_id, [Int], required: true
    end
    def allowed_jump_types(user_id: nil)
      # Get allowed jump types for each user:
      jump_type_ids = object.dropzone_user.where(user_id: user_id).map do |user|
        user.licensed_jump_types.pluck(:jump_type_id)
      end

      JumpType.where(id: jump_type_ids.reduce(&:intersection))
    end

    field :dropzone_user, Types::DropzoneUserType, null: true do
      argument :id, Int, required: true
    end
    def dropzone_user(id: nil)
      object.dropzone_users.includes(:user).find(id)
    end

    field :dropzone_users, Types::DropzoneUserType.connection_type, null: false do
      argument :permissions, [Types::PermissionType], required: false
      argument :search, String, required: false
    end
    def dropzone_users(permissions: nil, search: nil)
      query = object.dropzone_users.includes(:user)



      if permissions
        query = query.where(
          user_role_id: Permission.includes(
              user_role: :dropzone_users
            ).where(
              user_roles: {
                dropzone_users: {
                  dropzone_id: object.id
                  }
                }
              ).where(name: permissions.to_a).pluck("user_roles.id")
            )
      end

      query = query.search(name: search) if !search.nil?
      query || []
    end

    field :is_public, Boolean, null: false
    def is_public
      !!object.is_public
    end

    field :ticket_types, [Types::TicketTypeType], null: false do
      argument :is_public, Boolean, required: false
    end
    def ticket_types(is_public: nil)
      query = object.ticket_types
      query = query.where(is_public: is_public) unless is_public.nil?
      query.order(name: :asc)
    end


    field :planes, [Types::PlaneType], null: false
    field :loads, Types::LoadType.connection_type, null: false do
      argument :earliest_timestamp, Int, required: false
    end
    def loads(earliest_timestamp: nil)
      loads = object.loads
      loads = loads.where(
        "loads.created_at > ?",
        Time.at(earliest_timestamp)
      ) unless earliest_timestamp.nil?
      loads.order(created_at: :desc)
    end

    field :roles, [Types::UserRoleType], null: false
    def roles
      object.user_roles.order(id: :asc)
    end

    field :master_log, Types::MasterLogType, null: false,
    description: "Get the master log entry for a given date" do
      argument :date, Int, null: false,
      description: "This should be the timestamp of the beginning of the day"
    end
    def master_log(date: nil)
      log = object.master_log.find_or_initialize_by(created_at: Time.at(date))

      # Creating log record if none exists
      log.save! if log.new_record?
      log
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
