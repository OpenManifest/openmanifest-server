require 'spec_helper'

# Usage:
# it_behaves_like 'mutation', {
#   permissions: [:viewDropzone], # Not actually needed for creating one
#   expect: {
#     createDropzone: {
#       id: /\d/,
#       name: 'My Dropzone'
#     }
#   }
# }
#
# This should test:
# 1. Successful mutation when the user has required permissions
# 2. Unsuccessful mutation when the user doesn't have permissions
# 3. Field errors
# 4. Authorization
# 5. Mutation is hooked up to schema

shared_examples_for 'graphql' do |p, &block|
  let(:controller)  { instance_double(GraphqlDevise::GraphqlController) }

  # This lets us access let! variables and @instance variables in
  # the provided hash
  let!(:parameters) { p.is_a?(Proc) ? instance_exec(&p) : p }

  context 'and the user has the required permissions' do

    let!(:query) { Specs::Graphql::Client.new(parameters[:expect], actor: parameters[:actor], controller: controller).execute }

    describe 'the mutation exists in the schema' do
      it { expect(query.result.to_h['errors']).to eq nil }
      it { expect(query.result.to_h['errors']&.first).not_to include_json(message: /No operation named/) }
    end

    describe 'matches expected output' do
      it { expect(query.result['data']).to include_json(query.match_hash) }

      # Check again but print a more verbose message including the response
      it do
        expect(query.result['data']).to include_json(query.match_hash), -> do
          %Q(
            Matching failed for query:
            #{query.query_string}
            Response:
            #{query.result.to_json}
            Matcher:
            #{query.match_hash}
          )
        end
      end
    end
  end

  if @required_permissions&.any?
    context 'when the user doesnt have the required permissions' do
      before do
        # Set up permissions for the user
        if @required_permissions
          @required_permissions.each do |permission|
            parameters[:actor]&.revoke! permission
          end
        end

        parameters[:actor]&.reload_permissions
      end

      let!(:query) { Specs::Graphql::Client.new(parameters[:expect], actor: parameters[:actor], controller: controller).execute }
      let!(:error_json) { { errors: [/\s/], fieldErrors: nil } }

      describe 'matches expected output' do
        it { expect(query.result['data'][query.operation_name.to_s]).to include_json(error_json) }
      end
    end
  end
end