# frozen_string_literal: true

module Types
  class QueryType < Types::Base::Object
    include GraphQL::Types::Relay::HasNodeField
    include Geokit::Geocoders

    field :federations, resolver: Resolvers::Meta::Federations
    field :activity_types, resolver: Resolvers::Meta::ActivityTypes
    field :licenses,        resolver: Resolvers::Meta::Licenses
    field :current_user,    resolver: Resolvers::Access::CurrentUser
    field :membership,   resolver: Resolvers::Users::Membership
    field :memberships,  resolver: Resolvers::Users::Memberships
    field :daily_log, resolver: Resolvers::Operator::DailyLog

    field :industries, [Types::IndustryTemplateType], null: false,
                                                      description: "The industry templates an operator can be created from"
    def industries
      ::Industry.selectable
    end

    field :operators,       resolver: Resolvers::Operators
    field :operator,        resolver: Resolvers::Operator
    field :loads,           resolver: Resolvers::Operator::Loads
    field :load,            resolver: Resolvers::Operator::Load
    field :vehicles, resolver: Resolvers::Operator::Vehicles
    field :ticket_types,    resolver: Resolvers::Operator::TicketTypes
    field :extras,          resolver: Resolvers::Operator::TicketAddons
    field :available_rigs,  resolver: Resolvers::Operator::AvailableRigs
    field :activity,        resolver: Resolvers::Operator::Activity

    field :geocode, Types::Operator::GeocodedLocation, null: true,
                                                       description: "Find location by searching" do
      argument :search, String, required: true
    end
    def geocode(search: "")
      result = GoogleGeocoder.geocode(search)

      if result.success
        { lat: result.lat, lng: result.lng, formatted_string: result.full_address }
      else
        nil
      end
    end
  end
end
