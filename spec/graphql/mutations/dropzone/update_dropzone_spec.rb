# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::Setup::Dropzones::UpdateDropzone, type: :request do
  include_context 'dropzone'

  describe ".resolve" do
    before { fun_jumper.grant! :updateDropzone }
    subject do
      execute_query(
        id: dropzone.id,
        name: 'dopezone',
        allow_negative_credits: true,
        allow_manifest_bypass: true,
        require_license: false,
        require_credits: false,
        require_membership: false,
        require_rig_inspection: false
      )
    end

    it { is_expected.to include_json(updateDropzone: { dropzone: { id: dropzone.id.to_s, name: 'dopezone', settings: { allowNegativeCredits: true, allowManifestBypass: true, requireLicense: false, requireRigInspection: false, requireCredits: false, requireMembership: false }}}) }
  end

  create_query(:id, :name, :allow_negative_credits, :allow_manifest_bypass, :require_license, :require_rig_inspection, :require_credits, :require_membership) do
    <<-GQL
    mutation {
      updateDropzone(
        input: {
          id: #{id},
          attributes: {
            name: "#{name}",
            settings: {
              allowNegativeCredits: #{allow_negative_credits},
              allowManifestBypass: #{allow_manifest_bypass},
              requireLicense: #{require_license},
              requireRigInspection: #{require_rig_inspection},
              requireCredits: #{require_credits},
              requireMembership: #{require_membership}
            }
          }
        }
      ) {
        errors
        dropzone {
          id
          name
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
    }
    GQL
  end
end
