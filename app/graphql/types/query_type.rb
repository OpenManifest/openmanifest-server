# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Geokit::Geocoders

    field :image,           resolver: Resolvers::Image
    field :federations,     extras: [:lookahead],   resolver: Resolvers::Meta::Federations
    field :jump_types,      extras: [:lookahead],   resolver: Resolvers::Meta::JumpTypes
    field :licenses,        extras: [:lookahead],   resolver: Resolvers::Meta::Licenses
    field :current_user,    extras: [:lookahead],   resolver: Resolvers::Access::CurrentUser

    field :dropzones,       extras: [:lookahead],   resolver: Resolvers::Dropzones
    field :dropzone,        extras: [:lookahead],   resolver: Resolvers::Dropzone
    field :loads,           extras: [:lookahead],   resolver: Resolvers::Dropzone::Loads
    field :load,            extras: [:lookahead],   resolver: Resolvers::Dropzone::Load
    field :planes,          extras: [:lookahead],   resolver: Resolvers::Dropzone::Aircrafts
    field :ticket_types,    extras: [:lookahead],   resolver: Resolvers::Dropzone::TicketTypes
    field :extras,          extras: [:lookahead],   resolver: Resolvers::Dropzone::TicketAddons
    field :available_rigs,  extras: [:lookahead],   resolver: Resolvers::Dropzone::AvailableRigs
    field :activity,        extras: [:lookahead],   resolver: Resolvers::Dropzone::Activity

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
