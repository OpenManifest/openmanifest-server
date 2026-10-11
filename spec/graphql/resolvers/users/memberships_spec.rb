# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Users::Memberships, type: :request do
    include_context "operator"
    let!(:access_context) { ApplicationInteraction::AccessContext.new(instructor) }
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
        to_return(body: [].to_json, headers: { "Content-Type" => "application/json" })
    end
    let!(:student) { create(:membership, credits: 100, operator: operator, user: create(:user), user_role: operator.user_roles.default_licensed) }
    let!(:ghost) { ::Setup::Users::CreateGhost.run!(operator: operator, name: 'Fake User', phone: '1234567', exit_weight: 80, role: operator.user_roles.second, email: 'fake@email.com', access_context: access_context, license: operator.federation.licenses.last) }

    describe "Can see newly created ghost user" do
      subject do
        execute_query(operator_id: operator.id)
      end

      it { expect(subject[:memberships][:edges].size).to eq(4) }
      it { expect(subject[:memberships][:edges].map { |e| e[:node][:id] }).to match_array([fun_jumper, instructor, student, ghost.memberships.find_by(operator: operator)].map { |dz_user| dz_user.id.to_s }) }
    end

    create_query(:operator_id) do
      <<~GQL
        query {
          memberships(operator: #{operator_id}) {
            edges {
              node {
                id
              }
            }
          }
        }
      GQL
    end
  end
end
