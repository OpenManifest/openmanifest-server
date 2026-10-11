# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: subscription triggers" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:dropzone_user, dropzone: dropzone) }
  let!(:existing_load) { create(:load, plane: plane, pilot: pilot, gca: owner, load_master: owner) }

  def broadcasts(name)
    ActionCable.server.pubsub.broadcasts(name)
  end

  before { ActionCable.server.pubsub.clear }

  describe "subscription documents" do
    def validation_errors(document)
      query = GraphQL::Query.new(DzSchema, document)
      GraphQL::StaticValidation::Validator.new(schema: DzSchema).validate(query)[:errors]
    end

    it "validates LoadCreated against the schema" do
      document = ClientOperations.document("LoadCreated")

      expect(validation_errors(document)).to be_empty
      expect(document).to start_with("subscription LoadCreated")
    end

    it "validates LoadUpdated against the schema" do
      document = ClientOperations.document("LoadUpdated")

      expect(validation_errors(document)).to be_empty
      expect(document).to start_with("subscription LoadUpdated")
    end
  end

  describe "CreateLoad" do
    let(:variables) { { name: "Broadcast load", plane: plane.id, pilot: pilot.id, gca: owner.id } }

    it "broadcasts loadCreated for the dropzone" do
      client_operation("CreateLoad", variables: variables, as: owner_user)

      expect(broadcasts("graphql-event::loadCreated:dropzoneId:#{dropzone.id}")).not_to be_empty
    end

    it "does not broadcast to other dropzones" do
      other = create(:dropzone)

      client_operation("CreateLoad", variables: variables, as: owner_user)

      expect(broadcasts("graphql-event::loadCreated:dropzoneId:#{other.id}")).to be_empty
    end

    it "broadcasts loadCreated exactly once" do
      client_operation("CreateLoad", variables: variables, as: owner_user)

      expect(broadcasts("graphql-event::loadCreated:dropzoneId:#{dropzone.id}").size).to eq(1)
    end
  end

  describe "UpdateLoad" do
    it "broadcasts loadUpdated for the load" do
      client_operation("UpdateLoad", variables: { id: existing_load.id, attributes: { name: "Renamed" } }, as: owner_user)

      expect(broadcasts("graphql-event::loadUpdated:loadId:#{existing_load.id}")).not_to be_empty
    end

    it "does not broadcast for other loads" do
      other_load = create(:load, plane: plane, pilot: pilot, gca: owner)

      client_operation("UpdateLoad", variables: { id: existing_load.id, attributes: { name: "Renamed" } }, as: owner_user)

      expect(broadcasts("graphql-event::loadUpdated:loadId:#{other_load.id}")).to be_empty
    end

    it "broadcasts loadUpdated once for a call with a time and a state" do
      client_operation("UpdateLoad", variables: { id: existing_load.id, attributes: { dispatchAt: 10.minutes.from_now.iso8601, state: "boarding_call" } }, as: owner_user)

      expect(broadcasts("graphql-event::loadUpdated:loadId:#{existing_load.id}").size).to eq(1)
    end

    it "broadcasts loadUpdated once when the load lands" do
      existing_load.update!(dispatch_at: 10.minutes.from_now)
      existing_load.dispatch
      ActionCable.server.pubsub.clear

      client_operation("FinalizeLoad", variables: { id: existing_load.id, state: "landed" }, as: owner_user)

      expect(broadcasts("graphql-event::loadUpdated:loadId:#{existing_load.id}").size).to eq(1)
    end

    it "broadcasts loadUpdated exactly once" do
      client_operation("UpdateLoad", variables: { id: existing_load.id, attributes: { name: "Renamed" } }, as: owner_user)

      expect(broadcasts("graphql-event::loadUpdated:loadId:#{existing_load.id}").size).to eq(1)
    end
  end
end
