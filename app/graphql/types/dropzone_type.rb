# frozen_string_literal: true

module Types
  class DropzoneType < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::Wallet

    lookahead do |scope|
      scope = scope.includes(:user_roles)     if selects?(:user_roles) || selects?(:roles)
      scope = scope.includes(:ticket_types)   if selects?(:ticket_types)
      scope = scope.includes(:extras)         if selects?(:extras)
      scope = scope.includes(:rigs)           if selects?(:rigs)
      scope = scope.includes(:planes)         if selects?(:planes)
      scope = scope.includes(loads: :slots)   if selects?(:loads)
      scope = scope.includes(:dropzone_users) if selects?(:dropzone_users)
      scope
    end
    timestamp_fields

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :state, Types::Dropzone::State, null: false

    field :lat, Float, null: true
    field :lng, Float, null: true
    field :primary_color, String, null: true
    field :secondary_color, String, null: true
    field :is_credit_system_enabled, Boolean, null: false, method: :is_credit_system_enabled?
    field :current_user, Types::Users::DropzoneUser, null: false
    field :user_roles, [Types::Access::UserRole], null: false
    async_field :federation, Types::Meta::Federation, null: false
    async_field :rig_inspection_template, Types::Equipment::RigInspectionTemplate, null: true

    field :allowed_jump_types, [Types::Meta::JumpType], null: false do
      argument :user_id, [Int], required: true
    end

    def allowed_jump_types(user_id: nil)
      # Get allowed jump types for each user:
      JumpType.allowed_for(object.dropzone_users.where(id: user_id))
    end

    field :current_conditions, Types::Dropzone::Weather::Condition, null: false

    field :dropzone_user, Types::Users::DropzoneUser, null: true do
      argument :id, Int, required: false
      argument :user_id, Int, required: false
    end

    def dropzone_user(id: nil, user_id: nil)
      object.dropzone_users.find_by({ id: id, user_id: user_id }.compact)
    end

    field :ticket_types, [Types::Dropzone::Ticket], null: false do
      argument :is_public, Boolean, required: false
    end

    def ticket_types(is_public: true)
      return object.ticket_types.where(allow_manifesting_self: is_public) unless is_public.nil?
      object.ticket_types
    end

    field :extras, [Types::Dropzone::Tickets::Addon], null: false

    field :rigs, [Types::Equipment::Rig], null: true,
                                          description: "Get rigs for dropzone"

    field :planes, [Types::Dropzone::Aircraft], null: false, method: :planes

    field :roles, [Types::Access::UserRole], null: false do
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
      context[:current_resource].at(object)
    end

    def rigs
      return [] unless current_user.can?(:readDropzoneRig)
      object.rigs.order(rig_type: :asc)
    end

    def roles(selectable: nil)
      query = object.user_roles
      query = query.below(current_user.user_role) if selectable
      query.order(id: :asc)
    end

    def master_log(date: nil)
      log = object.master_logs.find_or_initialize_by(created_at: Time.at(date).to_datetime.all_day)

      # Creating log record if none exists
      log.save! if log.new_record?
      log
    end
  end
end
