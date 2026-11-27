# frozen_string_literal: true

require "rails_helper"

# BUG-001: the access context used to be a process-wide singleton, so concurrent requests overwrote each other's user and
# operator and the membership was memoised for the lifetime of the process.
RSpec.describe "Access context isolation" do
  # Private operators: a user sees only the ones they are staff at
  let(:operator_a) { create(:operator, state: "private") }
  let(:operator_b) { create(:operator, state: "private") }
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let!(:owner_a) { create(:membership, operator: operator_a, user: user_a, user_role: operator_a.user_roles.find_by(name: "owner")) }
  let!(:owner_b) { create(:membership, operator: operator_b, user: user_b, user_role: operator_b.user_roles.find_by(name: "owner")) }

  # Resolved through the access context (`operators` reads `access_context.operators`)
  let(:query) { "query { operators { edges { node { id } } } }" }

  def operator_ids(result)
    result.dig("data", "operators", "edges").to_a.map { |edge| edge.dig("node", "id") }
  end

  it "answers each request with that request's own user, one after the other" do
    [[user_a, operator_a], [user_b, operator_b], [user_a, operator_a]].each do |user, operator|
      post "/graphql", params: { query: query }, headers: user.create_new_auth_token
      expect(operator_ids(response.parsed_body)).to eq([operator.id.to_s])
    end
  end

  it "does not leak the identity between threads executing the schema at the same time" do
    # The data of this example lives in an uncommitted transaction: let the threads use the example's connection
    ActiveRecord::Base.connection_pool.pin_connection!(true)

    run = lambda do |user|
      Array.new(50) do
        access_context = AccessContext::CurrentUser.for(user)
        # A request spends time between building its context and using it; the other thread runs meanwhile
        sleep 0.001
        result = DzSchema.execute(query, context: { current_resource: user, access_context: access_context })
        operator_ids(result.to_h)
      end
    end

    # Compare on the main thread: the example's connection is shared with the threads while they run
    results = [[user_a, operator_a], [user_b, operator_b]].map do |user, operator|
      [operator, Thread.new { run.call(user) }]
    end.map { |operator, thread| [operator, thread.value] }

    results.each do |operator, id_lists|
      expect(id_lists).to all(eq([operator.id.to_s]))
    end
  ensure
    ActiveRecord::Base.connection_pool.unpin_connection!
  end
end
