# frozen_string_literal: true

module Types
  class QueryType < Types::Base::Object
    include GraphQL::Types::Relay::HasNodeField
    include Geokit::Geocoders

    field :federations,     resolver: Resolvers::Meta::Federations
    field :jump_types,      resolver: Resolvers::Meta::JumpTypes
    field :licenses,        resolver: Resolvers::Meta::Licenses
    field :current_user,    resolver: Resolvers::Access::CurrentUser
    field :dropzone_user,   resolver: Resolvers::Users::DropzoneUser
    field :dropzone_users,  resolver: Resolvers::Users::DropzoneUsers
    field :master_log,      resolver: Resolvers::Dropzone::MasterLog

    field :dropzones,       resolver: Resolvers::Dropzones
    field :dropzone,        resolver: Resolvers::Dropzone
    field :loads,           resolver: Resolvers::Dropzone::Loads
    field :load,            resolver: Resolvers::Dropzone::Load
    field :planes,          resolver: Resolvers::Dropzone::Aircrafts
    field :ticket_types,    resolver: Resolvers::Dropzone::TicketTypes
    field :extras,          resolver: Resolvers::Dropzone::TicketAddons
    field :available_rigs,  resolver: Resolvers::Dropzone::AvailableRigs
    field :activity,        resolver: Resolvers::Dropzone::Activity

    field :geocode, Types::Dropzone::GeocodedLocation, null: true,
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
