# frozen_string_literal: true

module Types
  class DropzoneType < Types::BaseObject
    implements Types::AnyResourceType
    implements Types::WalletType
    field :id, GraphQL::Types::ID, null: false

    field :name, String, null: true

    field :state, Types::Dropzone::State, null: false

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :lat, Float, null: true

    field :lng, Float, null: true

    field :federation, FederationType, null: false

    field :primary_color, String, null: true

    field :secondary_color, String, null: true

    field :rig_inspection_template, Types::FormTemplateType, null: true

    field :is_credit_system_enabled, Boolean, null: false, method: :is_credit_system_enabled?

    field :current_user, Types::DropzoneUserType, null: false

    field :user_roles, [Types::UserRoleType], null: false

    field :allowed_jump_types, [Types::JumpTypeType], null: false do
      argument :user_id, [Int], required: true
    end

    field :current_conditions, Types::WeatherConditionType, null: false

    field :dropzone_user, Types::DropzoneUserType, null: true do
      argument :id, Int, required: false
      argument :user_id, Int, required: false
    end

    def dropzone_user(id: nil, user_id: nil)
      object.dropzone_users.find_by({ id: id, user_id: user_id }.compact)
    end

    field :ticket_types, [Types::TicketTypeType], null: false do
      argument :is_public, Boolean, required: false
    end

    def ticket_types(is_public: true)
      return object.ticket_types.where(allow_manifesting_self: is_public) unless is_public.nil?
      object.ticket_types
    end

    field :extras, [Types::ExtraType], null: false

    field :rigs, [Types::RigType], null: true,
                                   description: "Get rigs for dropzone"

    field :planes, [Types::PlaneType], null: false, method: :planes

    field :roles, [Types::UserRoleType], null: false do
      argument :selectable, Boolean, required: false
    end

    field :master_log, Types::MasterLogType, null: false,
                                             description: "Get the master log entry for a given date" do
      argument :date, Int, required: true,
                           description: "This should be the timestamp of the beginning of the day"
    end

    field :banner, String, null: true, method: :banner_url

    field :statistics, Types::Admin::StatisticsType, null: false
    def statistics
      object
    end

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
      if dz_user.user.rigs.present? && dz_user.license.present? && dz_user.user.exit_weight.present?
        if dz_user.user_role_id == object.user_roles.first.id
          dz_user.update(user_role: object.user_roles.find_by(name: :fun_jumper))
        end

        # If the user has no rigs inspected at this dropzone,
        # notify a staff member if no previous notifications
        unless RigInspection.exists?(dropzone_user: dz_user)
          RequestRigInspectionJob.perform_now(dz_user.rigs.find { |rig| !rig.inspected_at?(object) }, dz_user)
        end
      end

      dz_user
    end

    def rigs
      if context[:current_resource].can?(:readDropzoneRig, dropzone_id: object.id)
        object.rigs.order(rig_type: :asc)
      else
        []
      end
    end

    def roles(selectable: nil)
      query = object.user_roles

      if selectable
        dz_user = object.dropzone_users.find_by(user_id: context[:current_resource].id)
        query = query.where("id < ?", dz_user.user_role_id)
      end

      query.order(id: :asc)
    end

    def master_log(date: nil)
      log = object.master_logs.find_or_initialize_by(created_at: Time.at(date))

      # Creating log record if none exists
      log.save! if log.new_record?
      log
    end
  end
end
