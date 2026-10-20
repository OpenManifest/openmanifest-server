# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Operator, type: :request do
    include_context "operator"

    describe "Can view Operator settings" do
      subject do
        execute_query(id: operator.id.to_s)
      end

      it { is_expected.to include_json(operator: { settings: { requireEquipmentInspection: true, requireCertification: true, requireCredits: true, allowManifestBypass: false, allowNegativeCredits: false } }) }
    end

    create_query(:id) do
      <<~GQL
        query {
          operator(id: "#{id}") {
            id
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
      GQL
    end
  end
end
