# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::Setup::Operators::UpdateOperator, type: :request do
  include_context 'operator'

  describe ".resolve" do
    before { fun_jumper.grant! :updateOperator }
    subject do
      execute_query(
        id: operator.id,
        name: 'dopezone',
        allow_negative_credits: true,
        allow_manifest_bypass: true,
        require_certification: false,
        require_credits: false,
        require_membership: false,
        require_equipment_inspection: false
      )
    end

    it { is_expected.to include_json(updateOperator: { operator: { id: operator.id.to_s, name: 'dopezone', settings: { allowNegativeCredits: true, allowManifestBypass: true, requireCertification: false, requireEquipmentInspection: false, requireCredits: false, requireMembership: false } } }) }
  end

  create_query(:id, :name, :allow_negative_credits, :allow_manifest_bypass, :require_certification, :require_equipment_inspection, :require_credits, :require_membership) do
    <<-GQL
    mutation {
      updateOperator(
        input: {
          id: #{id},
          attributes: {
            name: "#{name}",
            settings: {
              allowNegativeCredits: #{allow_negative_credits},
              allowManifestBypass: #{allow_manifest_bypass},
              requireCertification: #{require_certification},
              requireEquipmentInspection: #{require_equipment_inspection},
              requireCredits: #{require_credits},
              requireMembership: #{require_membership}
            }
          }
        }
      ) {
        errors
        operator {
          id
          name
          settings {
            requireEquipmentInspection
            requireCertification
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
