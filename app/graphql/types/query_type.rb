# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Geokit::Geocoders

    field :image,           resolvers: Resolvers::Image
    field :federations,     extras: [:lookahead],   resolver: Resolvers::Federations
    field :dropzones,       extras: [:lookahead],   resolver: Resolvers::Dropzones
    field :dropzone,        extras: [:lookahead],   resolver: Resolvers::Dropzone
    field :loads,           extras: [:lookahead],   resolver: Resolvers::Loads
    field :load,            extras: [:lookahead],   resolver: Resolvers::Load
    field :planes,          extras: [:lookahead],   resolver: Resolvers::Aircrafts
    field :ticket_types,    extras: [:lookahead],   resolver: Resolvers::TicketTypes
    field :extras,          extras: [:lookahead],   resolvers: Resolvers::TicketAddons
    field :jump_types,      extras: [:lookahead],   resolver: Resolvers::JumpTypes
    field :licenses,        extras: [:lookahead],   resolver: Resolvers::Licenses
    field :available_rigs,  extras: [:lookahead],   resolver: Resolvers::AvailableRigs
    field :activity,        extras: [:lookahead],   resolver: Resolvers::Activity

    field :geocode, Types::GeocodedLocationType, null: true,
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
