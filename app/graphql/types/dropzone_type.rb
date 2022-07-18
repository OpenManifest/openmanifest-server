# frozen_string_literal: true

module Types
  class DropzoneType < Types::BaseObject
    implements Types::AnyResourceType
    implements Types::WalletType
    field :id, GraphQL::Types::ID, null: false
    field :statistics, Types::Admin::StatisticsType, null: false
    def statistics
      {
        total_user_count: object.users_count,
        active_user_count: object.dropzone_users.kept.count,
        inactive_user_count: object.dropzone_users.discarded.count,
        gca_count: object.dropzone_users.with_acting_permission(:actAsGCA).count,
        dzso_count: object.dropzone_users.with_acting_permission(:actAsDZSO).count,
        pilot_count: object.dropzone_users.with_acting_permission(:actAsPilot).count,
        rig_inspector_count: object.dropzone_users.with_acting_permission(:actAsRigInspector).count,

        loads_count: object.loads.count,
        cancelled_loads_count: object.loads.cancelled.count,
        finalized_loads_count: object.loads.landed.count,
        revenue_cents_count: object.sales.where(state: :completed).sum(:amount)
      }
    end
    field :name, String, null: true
    field :request_publication, Boolean, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :lat, Float, null: true
    field :lng, Float, null: true
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
      unless dz_user = object.dropzone_users.find_by(user_id: context[:current_resource].id)
        dz_user = object.dropzone_users.find_or_create_by(
          user: context[:current_resource],
          user_role: object.user_roles.first
        )
      end

      # If the user has a rig, has set up exit weight, and
      # has a license, the user should be set to fun jumper
      # if the user is anything less
      if dz_user.user.rigs.present? && dz_user.license.present? && !dz_user.user.exit_weight.blank?
        if dz_user.user_role_id == object.user_roles.first.id
          dz_user.update(user_role: object.user_roles.find_by(name: :fun_jumper))
        end

        # If the user has no rigs inspected at this dropzone,
        # notify a staff member if no previous notifications
        unless RigInspection.where(dropzone_user: dz_user).exists?
          RequestRigInspectionJob.perform_now(dz_user.rigs.find { |rig| !rig.inspected_at?(object) }, dz_user)
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
      JumpType.allowed_for(object.dropzone_users.where(id: user_id))
    end

    field :current_conditions, Types::WeatherConditionType, null: false

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
      query = object.dropzone_users.includes(:user, :user_role, user_permissions: :permission)

      if licensed
        query = query.where.not(users: { license_id: nil })
      end

      if permissions
        query = query.where(
          user_role_id: UserRolePermission.includes(:permission, :user_role).where(
            permission: { name: permissions },
            user_role: { dropzone_id: object.id }
          ).pluck(:user_role_id)
        ).or(
          query.where(
            user_permissions: {
              permissions: { name: permissions }
            }
          )
        )
      end

      query = query.search(search) if !search.nil?

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
      object.planes
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

    field :roles, [Types::UserRoleType], null: false do
      argument :selectable, Boolean, required: false
    end
    def roles(selectable: nil)
      query = object.user_roles

      if selectable
        dz_user = object.dropzone_users.find_by(user_id: context[:current_resource].id)
        query = query.where("id < ?", dz_user.user_role_id)
      end

      query.order(id: :asc)
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
