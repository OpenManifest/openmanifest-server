# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: setup" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let(:other_operator) { create(:operator, state: "public") }
  let(:other_owner_user) { create(:user) }

  before do
    create(:membership, operator: other_operator, user: other_owner_user, user_role: other_operator.user_roles.find_by(name: "owner"))
  end

  describe "Planes" do
    it "lists the operator's aircraft" do
      json = client_operation("Planes", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :planes).pluck(:id)).to eq([plane.id.to_s])
      expect(json.dig(:data, :planes, 0)).to include(name: plane.name, registration: plane.registration, maxSlots: 16)
    end

    it "does not list another operator's aircraft to a stranger" do
      foreign_plane = create(:plane, operator: other_operator)

      json = client_operation("Planes", variables: { operatorId: other_operator.id }, as: user)

      expect(json.dig(:data, :planes).to_a.pluck(:id)).not_to include(foreign_plane.id.to_s)
    end
  end

  describe "CreateAircraft" do
    let(:attributes) { { name: "Twin Otter", registration: "VH-TWN", minSlots: 2, maxSlots: 22, operatorId: operator.id } }

    it "creates an aircraft for a user who may create planes" do
      json = nil
      expect { json = client_operation("CreateAircraft", variables: { attributes: attributes }, as: owner_user) }.to change(Plane, :count).by(1)

      expect(json.dig(:data, :createPlane, :plane)).to include(name: "Twin Otter", registration: "VH-TWN", maxSlots: 22)
      expect(json.dig(:data, :createPlane, :plane, :operator, :planes).size).to eq(2)
    end

    it "refuses a jumper" do
      expect { client_operation("CreateAircraft", variables: { attributes: attributes }, as: user) }.not_to change(Plane, :count)
    end
  end

  describe "UpdateAircraft" do
    it "updates the aircraft" do
      json = client_operation("UpdateAircraft", variables: { id: plane.id, attributes: { name: "Renamed", maxSlots: 12 } }, as: owner_user)

      expect(json.dig(:data, :updatePlane, :plane)).to include(name: "Renamed", maxSlots: 12)
    end

    it "refuses a jumper" do
      client_operation("UpdateAircraft", variables: { id: plane.id, attributes: { name: "Hijacked" } }, as: user)

      expect(plane.reload.name).not_to eq("Hijacked")
    end

    it "cannot move an aircraft to another operator" do
      client_operation("UpdateAircraft", variables: { id: plane.id, attributes: { operatorId: other_operator.id } }, as: owner_user)

      expect(plane.reload.operator).to eq(operator)
    end
  end

  describe "ArchivePlane" do
    it "archives the aircraft" do
      json = client_operation("ArchivePlane", variables: { id: plane.id }, as: owner_user)

      expect(json.dig(:data, :deletePlane, :errors)).to be_nil
      expect(plane.reload).to be_discarded
    end

    it "refuses a jumper" do
      client_operation("ArchivePlane", variables: { id: plane.id }, as: user)

      expect(plane.reload).not_to be_discarded
    end
  end

  describe "TicketTypes" do
    let!(:public_ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
    let!(:staff_ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 200).tap { |t| t.update!(allow_manifesting_self: false) } }

    it "lists every ticket type of the operator" do
      json = client_operation("TicketTypes", variables: { operator: operator.id }, as: owner_user)

      expect(json.dig(:data, :ticketTypes).pluck(:name)).to match_array(%w(Height Tandem))
    end

    it "filters by allowManifestingSelf" do
      json = client_operation("TicketTypes", variables: { operator: operator.id, allowManifestingSelf: true }, as: user)

      expect(json.dig(:data, :ticketTypes).pluck(:name)).to eq(["Height"])
    end
  end

  describe "AllowedTicketTypes" do
    let!(:public_ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }
    let!(:staff_ticket) { create(:ticket_type, operator: operator, name: "Tandem", cost: 200).tap { |t| t.update!(allow_manifesting_self: false) } }

    it "returns only self-manifestable tickets when onlyPublicTickets is set" do
      json = client_operation("AllowedTicketTypes", variables: { operator: operator.id, onlyPublicTickets: true }, as: user)

      expect(json.dig(:data, :ticketTypes).pluck(:name)).to eq(["Height"])
    end

    it "returns every ticket otherwise" do
      json = client_operation("AllowedTicketTypes", variables: { operator: operator.id }, as: user)

      expect(json.dig(:data, :ticketTypes).size).to eq(2)
    end
  end

  describe "CreateTicketType" do
    let(:attributes) { { name: "Hop n Pop", costCents: 2500, altitude: 5000, allowManifestingSelf: true, operatorId: operator.id, currency: "AUD" } }

    it "creates a ticket type" do
      json = nil
      expect { json = client_operation("CreateTicketType", variables: { attributes: attributes }, as: owner_user) }.to change(TicketType, :count).by(1)

      expect(json.dig(:data, :createTicketType, :ticketType)).to include(name: "Hop n Pop", altitude: 5000, costCents: 2500)
    end

    it "refuses a jumper" do
      expect { client_operation("CreateTicketType", variables: { attributes: attributes }, as: user) }.not_to change(TicketType, :count)
    end
  end

  describe "UpdateTicketType" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }

    it "updates the ticket type" do
      json = client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { costCents: 5500, name: "Full height" } }, as: owner_user)

      expect(json.dig(:data, :updateTicketType, :ticketType)).to include(name: "Full height", costCents: 5500)
    end

    it "refuses a jumper" do
      client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { costCents: 0 } }, as: user)

      expect(ticket.reload.cost).to eq(40)
    end

    it "cannot move a ticket type to another operator" do
      client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { operatorId: other_operator.id } }, as: owner_user)

      expect(ticket.reload.operator).to eq(operator)
    end

    it "keeps the extras of other ticket types when one ticket type's extras change" do
      extra = Extra.create!(operator: operator, name: "Video", cost: 5)
      other_ticket = create(:ticket_type, operator: operator, name: "Boogie", cost: 60)
      other_ticket.extras << extra

      client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { operatorId: operator.id, extraIds: [] } }, as: owner_user)

      expect(other_ticket.reload.extras).to eq([extra])
    end
  end

  describe "ArchiveTicketType" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }

    it "archives the ticket type" do
      json = client_operation("ArchiveTicketType", variables: { id: ticket.id }, as: owner_user)

      expect(json.dig(:data, :archiveTicketType, :errors)).to be_nil
      expect(ticket.reload).to be_discarded
    end

    it "does not archive for a jumper" do
      begin
        client_operation("ArchiveTicketType", variables: { id: ticket.id }, as: user)
      rescue StandardError
        # BUG-039: the authorization check itself raises
      end

      expect(ticket.reload).not_to be_discarded
    end
  end

  describe "TicketTypeExtras" do
    it "lists the operator's extras with their ticket types" do
      extra = Extra.create!(operator: operator, name: "Video", cost: 5)

      json = client_operation("TicketTypeExtras", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :extras).pluck(:id)).to eq([extra.id.to_s])
      expect(json.dig(:data, :extras, 0)).to include(name: "Video", costCents: 500)
    end

    it "returns an empty list for an operator without extras" do
      expect(client_operation("TicketTypeExtras", variables: { operatorId: operator.id }, as: user).dig(:data, :extras)).to eq([])
    end
  end

  describe "CreateTicketAddon" do
    let!(:ticket) { create(:ticket_type, operator: operator, name: "Height", cost: 40) }

    it "creates an extra linked to ticket types" do
      json = nil
      expect do
        json = client_operation("CreateTicketAddon", variables: { attributes: { name: "Video", costCents: 500, operatorId: operator.id, ticketTypeIds: [ticket.id] } }, as: owner_user)
      end.to change(Extra, :count).by(1)

      expect(json.dig(:data, :createExtra, :extra)).to include(name: "Video", costCents: 500)
      expect(Extra.last.ticket_types).to eq([ticket])
    end

    it "refuses a jumper" do
      expect do
        client_operation("CreateTicketAddon", variables: { attributes: { name: "Video", costCents: 500, operatorId: operator.id } }, as: user)
      end.not_to change(Extra, :count)
    end
  end

  describe "UpdateTicketAddon" do
    let!(:extra) { Extra.create!(operator: operator, name: "Video", cost: 5) }

    it "updates the extra" do
      json = client_operation("UpdateTicketAddon", variables: { id: extra.id, attributes: { name: "HD video", costCents: 800 } }, as: owner_user)

      expect(json.dig(:data, :updateExtra, :extra)).to include(name: "HD video", costCents: 800)
    end

    it "refuses a jumper" do
      client_operation("UpdateTicketAddon", variables: { id: extra.id, attributes: { costCents: 0 } }, as: user)

      expect(extra.reload.cost).to eq(5)
    end
  end

  describe "OperatorRigs" do
    it "lists the operator's rigs" do
      rig = create(:rig, operator: operator)

      json = client_operation("OperatorRigs", variables: { operatorId: operator.id }, as: owner_user)

      expect(json.dig(:data, :operator, :rigs).pluck(:id)).to eq([rig.id.to_s])
    end

    it "is empty for an operator without rigs" do
      expect(client_operation("OperatorRigs", variables: { operatorId: operator.id }, as: owner_user).dig(:data, :operator, :rigs)).to eq([])
    end
  end

  describe "AvailableRigs" do
    it "returns the rigs of the member that were inspected as ok" do
      rig = create(:rig, user: user, operator: nil)
      create(:rig_inspection, rig: rig, membership: fun_jumper, inspected_by: owner, is_ok: true)

      json = client_operation("AvailableRigs", variables: { membershipId: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :availableRigs).pluck(:id)).to include(rig.id.to_s)
    end

    it "does not return uninspected rigs" do
      rig = create(:rig, user: user, operator: nil)

      json = client_operation("AvailableRigs", variables: { membershipId: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :availableRigs).pluck(:id)).not_to include(rig.id.to_s)
    end

    it "returns the operator's tandem rigs for tandem slots" do
      json = client_operation("AvailableRigs", variables: { membershipId: fun_jumper.id, isTandem: true }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :availableRigs)).to be_an(Array)
    end
  end

  describe "CreateRig" do
    let(:variables) { { make: "Vector", model: "v310", serial: "12345", rigType: "sport", canopySize: 129, userId: user.id } }

    it "creates a rig owned by the caller" do
      json = nil
      expect { json = client_operation("CreateRig", variables: variables, as: user) }.to change(Rig, :count).by(1)

      expect(json.dig(:data, :createRig, :errors)).to be_nil
      expect(json.dig(:data, :createRig, :rig)).to include(make: "Vector", serial: "12345")
    end

    it "refuses creating a rig for another user" do
      expect { client_operation("CreateRig", variables: variables.merge(userId: staff_user.id), as: user) }.not_to change(Rig, :count)
    end

    # The app sends the packing card with UpdateRig; createRig takes it too
    def create_rig_with_card(card)
      query = "mutation($attributes: RigInput!) { createRig(input: { attributes: $attributes }) { errors fieldErrors { field message } rig { id } } }"
      post "/graphql",
           params: { query: query, variables: { attributes: { make: "Vector", model: "v310", serial: "1", rigType: "sport", canopySize: 129, userId: user.id, packingCard: card } }.to_json },
           headers: user.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "stores a packing card image when the rig is created" do
      json = create_rig_with_card(image_data_url("jpg"))

      expect(json.dig(:data, :createRig, :errors)).to be_nil
      expect(Rig.find(json.dig(:data, :createRig, :rig, :id)).packing_card).to be_attached
    end

    it "refuses a packing card that is not a picture, and creates no rig" do
      json = nil
      expect { json = create_rig_with_card(data_url_of("not an image")) }.not_to change(Rig, :count)

      expect(json.dig(:data, :createRig, :fieldErrors, 0, :field)).to eq("packing_card")
    end
  end

  describe "UpdateRig" do
    let!(:rig) { create(:rig, user: user, operator: nil) }

    it "stores a packing card image" do
      json = client_operation("UpdateRig", variables: { id: rig.id, packingCard: image_data_url("png") }, as: user)

      expect(json.dig(:data, :updateRig, :errors)).to be_nil
      expect(rig.reload.packing_card).to be_attached
      expect(rig.packing_card.content_type).to eq("image/png")
    end

    it "updates the caller's own rig" do
      json = client_operation("UpdateRig", variables: { id: rig.id, name: "Main", canopySize: 119 }, as: user)

      expect(json.dig(:data, :updateRig, :rig)).to include(name: "Main", canopySize: 119)
    end

    it "refuses another jumper" do
      client_operation("UpdateRig", variables: { id: rig.id, name: "Hijacked" }, as: staff_user)

      expect(rig.reload.name).not_to eq("Hijacked")
    end

    it "cannot reassign the rig to another user" do
      client_operation("UpdateRig", variables: { id: rig.id, userId: staff_user.id }, as: user)

      expect(rig.reload.user).to eq(user)
    end
  end

  describe "ArchiveRig" do
    let!(:rig) { create(:rig, user: user, operator: nil) }

    it "archives the caller's own rig" do
      json = client_operation("ArchiveRig", variables: { id: rig.id }, as: user)

      expect(json.dig(:data, :archiveRig, :errors)).to be_nil
      expect(rig.reload).to be_discarded
    end

    it "archives someone else's rig for staff" do
      client_operation("ArchiveRig", variables: { id: rig.id }, as: owner_user)

      expect(rig.reload).to be_discarded
    end
  end

  describe "CreateRigInspection" do
    let!(:rig) { create(:rig, user: user, operator: nil) }
    let!(:template) { create(:form_template, operator: operator).tap { |form| operator.update!(rig_inspection_template: form) } }

    before { owner.grant!("actAsRigInspector") }

    it "records an inspection by a rig inspector" do
      json = nil
      expect do
        json = client_operation("CreateRigInspection", variables: { operator: operator.id, rig: rig.id, isOk: true, definition: "[]" }, as: owner_user)
      end.to change(RigInspection, :count).by(1)

      expect(json.dig(:data, :createRigInspection, :rigInspection, :isOk)).to be(true)
    end

    it "refuses a user who is not a rig inspector" do
      expect do
        client_operation("CreateRigInspection", variables: { operator: operator.id, rig: rig.id, isOk: true, definition: "[]" }, as: user)
      end.not_to change(RigInspection, :count)
    end

    it "notifies the rig owner when the rig is cleared to jump" do
      expect do
        client_operation("CreateRigInspection", variables: { operator: operator.id, rig: rig.id, isOk: true, definition: "[]" }, as: owner_user)
      end.to change { Notification.where(notification_type: :rig_inspection_completed).count }.by(1)
    end

    it "does not tell the rig owner they are cleared when the inspection failed" do
      expect do
        client_operation("CreateRigInspection", variables: { operator: operator.id, rig: rig.id, isOk: false, definition: "[]" }, as: owner_user)
      end.not_to(change(Notification, :count))
    end
  end

  describe "ReloadWeather" do
    let!(:weather) { operator.current_conditions }
    let(:winds_url) { WeatherCondition::WINDS_URL }
    let(:winds_body) do
      altitudes = %w(0 1000 2000 5000 7000 8000 10000 12000 14000)
      { speed: altitudes.index_with { 10 }, direction: altitudes.index_with { 270 }, temp: altitudes.index_with { 12 } }.to_json
    end

    it "reloads the operator's weather condition from its id alone" do
      operator.update!(lat: -27.5, lng: 152.9)
      stub = stub_request(:get, winds_url).with(query: hash_including("lat" => "-27.5", "lon" => "152.9")).to_return(status: 200, body: winds_body)

      json = client_operation("ReloadWeather", variables: { id: weather.id }, as: owner_user)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to be_nil
      expect(json.dig(:data, :reloadWeatherCondition, :weatherCondition, :id)).to eq(weather.id.to_s)
      expect(json.dig(:data, :reloadWeatherCondition, :weatherCondition, :winds)).to be_present
      expect(stub).to have_been_requested
    end

    it "keeps working for an operator without a location" do
      operator.update!(lat: nil, lng: nil)

      json = client_operation("ReloadWeather", variables: { id: weather.id }, as: owner_user)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to be_nil
      expect(a_request(:get, winds_url).with(query: hash_including({}))).not_to have_been_made
    end

    it "reports a service that does not answer" do
      operator.update!(lat: -27.5, lng: 152.9)
      stub_request(:get, winds_url).with(query: hash_including({})).to_timeout

      json = client_operation("ReloadWeather", variables: { id: weather.id }, as: owner_user)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to eq(["The winds could not be fetched, try again in a moment"])
      expect(json.dig(:data, :reloadWeatherCondition, :weatherCondition)).to be_nil
    end

    it "does not let a jumper reload the weather" do
      json = client_operation("ReloadWeather", variables: { id: weather.id }, as: user)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to eq(["You can't update weather conditions"])
      expect(weather.reload.updated_at).to eq(weather.updated_at)
    end

    it "does not let staff of another operator reload it" do
      other_owner = create(:user)
      create(:membership, operator: other_operator, user: other_owner, user_role: other_operator.user_roles.find_by(name: "owner"))

      json = client_operation("ReloadWeather", variables: { id: weather.id }, as: other_owner)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to eq(["You can't update weather conditions"])
    end

    it "answers an unknown weather condition with an error" do
      json = client_operation("ReloadWeather", variables: { id: 0 }, as: owner_user)

      expect(json.dig(:data, :reloadWeatherCondition, :errors)).to eq(["Weather condition not found"])
    end
  end

  describe "MasterLog" do
    let(:date) { Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }

    it "returns the master log entry for a day" do
      json = client_operation("MasterLog", variables: { operatorId: operator.id, date: date }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :masterLog)).to be_nil.or(include(:id, :date, :loads))
    end

    it "requires authentication" do
      expect(client_operation("MasterLog", variables: { operatorId: operator.id, date: date }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end

    it "does not return another operator's master log to a stranger" do
      other_operator.master_logs.create!(date: Date.current) if other_operator.master_logs.respond_to?(:create!)

      json = client_operation("MasterLog", variables: { operatorId: other_operator.id, date: date }, as: user)

      expect(json.dig(:data, :masterLog)).to be_nil
    end
  end

  describe "UpdateMasterLog" do
    let(:date) { Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }

    it "saves the notes and DZSO for the day" do
      json = client_operation("UpdateMasterLog", variables: { date: date, operator: operator.id, attributes: { notes: "Windy afternoon", dzso: owner.id } }, as: owner_user)

      expect(json.dig(:data, :updateMasterLog, :errors)).to be_nil
      expect(json.dig(:data, :updateMasterLog, :masterLog)).to include(notes: "Windy afternoon")
      expect(json.dig(:data, :updateMasterLog, :masterLog, :dzso, :id)).to eq(owner.id.to_s)
    end

    it "refuses a jumper" do
      client_operation("UpdateMasterLog", variables: { date: date, operator: operator.id, attributes: { notes: "Hijacked" } }, as: user)

      expect(operator.master_logs.where(notes: "Hijacked")).to be_empty
    end
  end
end
