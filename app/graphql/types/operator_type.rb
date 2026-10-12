# frozen_string_literal: true

module Types
  class OperatorType < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::Wallet

    timestamp_fields

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :state, Types::Operator::State, null: false

    field :lat, Float, null: true
    field :lng, Float, null: true
    field :primary_color, String, null: true
    field :secondary_color, String, null: true
    field :is_credit_system_enabled, Boolean, null: false, method: :is_credit_system_enabled?
    field :current_user, Types::Users::Membership, null: true,
                                                   description: "The caller's membership of this operator, or null if they have not joined it (see joinOperator)"
    async_field :user_roles, [Types::Access::UserRole], null: false
    field :settings, Types::Operator::Settings, null: true
    field :industry, Types::IndustryEnum, null: false, description: "The industry template the operator was created from"
    field :modules, GraphQL::Types::JSON, null: false, description: "The enabled modules with their configuration"
    def modules
      ::Industry::MODULES.filter_map { |name| [name, object.module_config(name)] if object.module?(name) }.to_h
    end
    field :call_schedule_minutes, [Int], null: false, description: "Minutes before departure at which a boarding call is offered: the operator's own, else its template's"
    field :terminology, GraphQL::Types::JSON, null: false, description: "Terms of the operator's industry, with its own changes" do
      argument :locale, String, required: false, default_value: "en"
    end
    def terminology(locale: "en")
      object.terminology(locale)
    end
    field :units, GraphQL::Types::JSON, null: false, description: "The units the operator shows"
    async_field :federation, Types::Meta::Federation, null: false
    async_field :rig_inspection_template, Types::Equipment::RigInspectionTemplate, null: true

    field :allowed_activity_types, [Types::Meta::ActivityType], null: false do
      argument :user_id, [Int], required: true
    end

    def allowed_activity_types(user_id: nil)
      # Get allowed jump types for each user:
      ActivityType.allowed_for(object.memberships.where(id: user_id))
    end

    field :current_conditions, Types::Operator::Weather::Condition, null: false

    field :time_zone, String, null: false, description: "The operator's time zone (IANA name): its days, and the times of its loads, are in it"

    field :membership, Types::Users::Membership, null: true do
      argument :id, Int, required: false
      argument :user_id, Int, required: false
    end

    def membership(id: nil, user_id: nil)
      object.memberships.find_by({ id: id, user_id: user_id }.compact)
    end

    field :ticket_types, [Types::Operator::Ticket], null: false do
      argument :is_public, Boolean, required: false
    end

    def ticket_types(is_public: true)
      ticket_types = dataloader.with(::Sources::AssociationLoader, [:ticket_types]).load(object).ticket_types
      return ticket_types if is_public.nil?

      ticket_types.select { |ticket_type| ticket_type.allow_manifesting_self == is_public }
    end

    async_field :extras, [Types::Operator::Tickets::Addon], null: false

    field :rigs, [Types::Equipment::Rig], null: true,
                                          description: "Get rigs for operator"

    async_field :vehicles, [Types::Operator::Vehicle], null: false

    field :crew_roles, [Types::Operator::CrewRole], null: false, description: "The jobs on a load of this operator"
    def crew_roles
      object.crew_roles.kept.ordered
    end

    field :destinations, [Types::Operator::Destination], null: false,
                                                         description: "The places this operator's loads go to" do
      argument :kind, Types::Operator::DestinationKind, required: false
    end
    def destinations(kind: nil)
      scope = object.destinations.order(:name)
      kind ? scope.where(kind: kind) : scope
    end

    field :roles, [Types::Access::UserRole], null: false do
      argument :selectable, Boolean, required: false
    end

    field :daily_log, Types::DailyLogType, null: false,
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
      return [] unless current_user&.can?(:readOperatorRig)
      object.rigs.order(rig_type: :asc)
    end

    def roles(selectable: nil)
      query = object.user_roles
      query = (current_user ? query.below(current_user.user_role) : query.none) if selectable
      query.order(id: :asc)
    end

    def daily_log(date: nil)
      # The day the timestamp falls on in the operator's time zone
      object.daily_logs.find_or_create_by!(date: Time.zone.at(date).in_time_zone(object.time_zone).to_date)
    end
  end
end
