# frozen_string_literal: true

class Types::IndustryManifestLink < Types::Base::Enum
  graphql_name "ManifestLink"

  value "CHECKIN", "A booking becomes a slot when the person checks in", value: "checkin"
  value "LOAD", "A booking is for a load that is scheduled ahead", value: "load"
end
