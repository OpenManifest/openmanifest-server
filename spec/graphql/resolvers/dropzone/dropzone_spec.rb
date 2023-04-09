# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Dropzone, type: :request do
    include_context "dropzone"

    describe "Can view Dropzone settings" do
      subject do
        execute_query(id: dropzone.id.to_s)
      end

      it { is_expected.to include_json(dropzone: { settings: { requireRigInspection: true, requireLicense: true, requireCredits: true, allowManifestBypass: false, allowNegativeCredits: false }}) }
    end

    create_query(:id) do
      <<~GQL
        query {
          dropzone(id: "#{id}") {
            id
            settings {
              requireRigInspection
              requireLicense
              requireCredits
              requireMembership
              allowNegativeCredits
              allowManifestBypass
            }
          }
        }
      GQL
    end
  end
end
