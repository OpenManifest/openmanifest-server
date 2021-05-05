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
    field :rig_inspection_template, Types::FormTemplateType, null: true
    field :is_credit_system_enabled, Boolean, null: false
    def is_credit_system_enabled
      object.is_credit_system_enabled?
    end
    
    field :current_user, Types::DropzoneUserType, null: false
    def current_user
      dz_user = object.dropzone_users.find_or_initialize_by(
        user: context[:current_resource]
      )

      
      if dz_user.new_record?
        dz_user.user_role = object.user_roles.first
        dz_user.save
      end

      # If the user has a rig, has set up exit weight, and
      # has a license, the user should be set to fun jumper
      # if the user is anything less
      if dz_user.user.rigs.present? && dz_user.user.license.present? && !dz_user.user.exit_weight.blank?
        if dz_user.user_role_id == object.user_roles.first.id
          dz_user.update(user_role: object.user_roles.second)
        end
      end

      dz_user
    end

    field :user_roles, [Types::UserRoleType], null: false

    field :allowed_jump_types, [Types::JumpTypeType], null: false do
      argument :user_id, [Int], required: true
    end
    def allowed_jump_types(user_id: nil)
      # Get allowed jump types for each user:
      jump_type_ids = object.dropzone_users.where(user_id: user_id).map do |dz_user|
        dz_user.user.licensed_jump_types.pluck(:jump_type_id)
      end

      JumpType.where(id: jump_type_ids.reduce(&:intersection))
    end

    field :dropzone_user, Types::DropzoneUserType, null: true do
      argument :id, Int, required: false
      argument :user_id, Int, required: false
    end
    def dropzone_user(id: nil, user_id: nil)
      if id
        object.dropzone_users.includes(:user).find(id)
      elsif user_id
        object.dropzone_users.includes(:user).find_by(user_id: user_id)
      end
    end

    field :dropzone_users, Types::DropzoneUserType.connection_type, null: false do
      argument :permissions, [Types::PermissionType], required: false
      argument :search, String, required: false
      argument :licensed, Boolean, required: false
    end
    def dropzone_users(permissions: nil, search: nil, licensed: nil)
      query = object.dropzone_users.includes(:user)

      if licensed
        query = query.where.not(users: { license_id: nil })
      end

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
      query = object.ticket_types.where(is_deleted: false)
      query = query.where(allow_manifesting_self: is_public) unless is_public.nil?
      query.order(name: :asc)
    end

    field :extras, [Types::ExtraType], null: false
    def extras
      Extra.includes(ticket_type_extras: :ticket_type).where(dropzone_id: object.id).order(name: :asc)
    end

    field :rigs, [Types::RigType], null: true,
    description: "Get rigs for dropzone"
    def rigs
      if context[:current_resource].can?(:readDropzoneRig, dropzone_id: object.id)
        object.rigs.order(rig_type: :asc)
      else 
        []
      end 
    end


    field :planes, [Types::PlaneType], null: false
    def planes
      object.planes.where(is_deleted: false)
    end

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
      argument :date, Int, required: true,
      description: "This should be the timestamp of the beginning of the day"
    end
    def master_log(date: nil)
      log = object.master_logs.find_or_initialize_by(created_at: Time.at(date))

      # Creating log record if none exists
      log.save! if log.new_record?
      log
    end

    
    field :banner, String, null: true
    def banner
      object.image_url
    rescue ActiveStorage::FileNotFoundError
      nil
    end
  end
end
