# frozen_string_literal: true

require "rails_helper"

# BUG-049: the manifest board and the member list run a bounded number of queries however many loads, slots and members
# there are. Prosopite fails the request when it sees the same query shape repeated for sibling records.
RSpec.describe "N+1 queries on the board and the member list" do
  include_context "dropzone"

  let!(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  # A member can be on one load at a time, so 5 loads of 10 slots take 50 members
  let!(:members) do
    Array.new(50) { create(:dropzone_user, dropzone: dropzone, user_role: dropzone.user_roles.default_licensed, credits: 1000) }
  end
  let!(:loads) do
    Array.new(5) { create(:load, plane: plane, pilot: owner, gca: owner, load_master: owner) }
  end
  let!(:slots) do
    loads.each_with_index.flat_map do |manifested, index|
      members.slice(index * 10, 10).map do |member|
        create(:slot, load: manifested, dropzone_user: member, dropzone: dropzone, jump_type: JumpType.allowed_for([member]).first)
      end
    end
  end

  # The lists have 5 loads, 10 slots each and 50 members, so a query repeated for each of them runs 5 times or more. The
  # dataloader answers the same kind of record in a few rounds as the fields of different depths reach it (the crew of a
  # load, then the members of its slots), which is up to 3 queries and not an N+1.
  around do |example|
    Prosopite.raise = true
    Prosopite.min_n_queries = 4
    example.run
  ensure
    Prosopite.raise = false
    Prosopite.min_n_queries = 2
  end

  def without_n_plus_one(&block)
    Prosopite.scan(&block)
  end

  it "loads the board, 5 loads of 10 slots, in a bounded number of queries" do
    json = nil
    without_n_plus_one { json = client_operation("Loads", variables: { dropzone: dropzone.id, date: Date.current.iso8601 }, as: owner_user) }

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :loads, :edges).size).to eq(5)
    expect(json.dig(:data, :loads, :edges, 0, :node)).to include(weight: be_positive, maxSlots: 16, occupiedSlots: 10)
  end

  it "lists 50 members in a bounded number of queries" do
    json = nil
    without_n_plus_one { json = client_operation("DropzoneUsers", variables: { dropzoneId: dropzone.id, first: 50, licensed: nil }, as: owner_user) }

    expect(json[:errors]).to be_nil
    expect(json.dig(:data, :dropzoneUsers, :edges).size).to be >= 50
  end

  # Every field the screens read from a member or a load, not just the fragments of the list queries
  describe "with every computed field selected" do
    let(:member_fields) do
      "id credits creditsCents expiresAt hasMembership hasCredits hasExitWeight hasLicense hasRigInspection hasReserveInDate " \
        "unseenNotifications permissions role { id name } license { id name } user { id name image } rigInspections { id }"
    end

    def graphql_as(user, query, variables = {})
      post "/graphql", params: { query: query, variables: variables.to_json }, headers: user.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "lists members with their computed fields" do
      json = nil
      query = "query($dropzone: ID!) { dropzoneUsers(dropzone: $dropzone, first: 100, licensed: false) { edges { node { #{member_fields} } } } }"
      without_n_plus_one { json = graphql_as(owner_user, query, dropzone: dropzone.id) }

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :dropzoneUsers, :edges).size).to be >= 50
    end

    # The fragments the client uses for one load, selected for every load of the day
    it "lists loads with their slots, crew and plane" do
      json = nil
      query = ClientOperations.document("Load") + <<~GQL
        query LoadsDetailed($dropzone: ID!, $date: ISO8601Date) {
          loads(dropzone: $dropzone, date: $date) { edges { node { ...loadDetails } } }
        }
      GQL
      without_n_plus_one do
        post "/graphql", params: { query: query, variables: { dropzone: dropzone.id, date: Date.current.iso8601 }.to_json, operationName: "LoadsDetailed" },
                         headers: owner_user.create_new_auth_token
        json = response.parsed_body.with_indifferent_access
      end

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :loads, :edges, 0, :node, :slots).size).to eq(10)
    end
  end
end
