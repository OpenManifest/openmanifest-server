# frozen_string_literal: true

require "rails_helper"

module Mutations
  RSpec.describe Resolvers::Users::DropzoneUsers, type: :request do
    include_context "dropzone"
    let!(:access_context) { ApplicationInteraction::AccessContext.new(instructor) }
    before do
      stub_request(:get, /www.apf.com.au\/apf\/api\/student/).
        to_return(body: [].to_json, headers: { "Content-Type" => "application/json" })
    end
    let!(:student) { create(:dropzone_user, credits: 100, dropzone: dropzone, user: create(:user), user_role: dropzone.user_roles.default_licensed) }
    let!(:ghost) { ::Setup::Users::CreateGhost.run!(dropzone: dropzone, name: 'Fake User', phone: '1234567', exit_weight: 80, role: dropzone.user_roles.second, email: 'fake@email.com', access_context: access_context, license: dropzone.federation.licenses.last) }

    describe "Can see newly created ghost user" do
      subject do
        execute_query(dropzone_id: dropzone.id)
      end

      it { expect(subject[:dropzoneUsers][:edges].size).to eq(4) }
      it { is_expected.to include_json(dropzoneUsers: { edges: [{ node: { id: fun_jumper.id.to_s } }, { node: { id: instructor.id.to_s } }, { node: { id: student.id.to_s } }, { node: { id: ghost.id.to_s } }] }) }
    end

    create_query(:dropzone_id) do
      <<~GQL
        query {
          dropzoneUsers(dropzone: #{dropzone_id}) {
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
