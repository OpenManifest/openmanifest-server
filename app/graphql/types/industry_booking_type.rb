# frozen_string_literal: true

class Types::IndustryBookingType < Types::Base::Object
  graphql_name "IndustryBooking"
  description "What an industry template says about bookings (the booking plan builds on it)"

  field :manifest_link, Types::IndustryManifestLink, null: false,
                                                     description: "How a booking reaches the manifest: CHECKIN (put on a load when the person arrives) or LOAD (made for a load scheduled ahead)"
end
