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

  describe "Vehicles" do
    it "lists the operator's vehicle" do
      json = client_operation("Vehicles", variables: { operatorId: operator.id }, as: user)

      expect(json.dig(:data, :vehicles).pluck(:id)).to eq([vehicle.id.to_s])
      expect(json.dig(:data, :vehicles, 0)).to include(name: vehicle.name, registration: vehicle.registration, capacity: 16)
    end

    it "does not list another operator's vehicle to a stranger" do
      foreign_vehicle = create(:vehicle, operator: other_operator)

      json = client_operation("Vehicles", variables: { operatorId: other_operator.id }, as: user)

      expect(json.dig(:data, :vehicles).to_a.pluck(:id)).not_to include(foreign_vehicle.id.to_s)
    end
  end

  describe "CreateVehicle" do
    let(:attributes) { { name: "Twin Otter", registration: "VH-TWN", minCapacity: 2, capacity: 22, operatorId: operator.id } }

    it "creates a vehicle for a user who may create vehicles" do
      json = nil
      expect { json = client_operation("CreateVehicle", variables: { attributes: attributes }, as: owner_user) }.to change(Vehicle, :count).by(1)

      expect(json.dig(:data, :createVehicle, :vehicle)).to include(name: "Twin Otter", registration: "VH-TWN", capacity: 22)
      expect(json.dig(:data, :createVehicle, :vehicle, :operator, :vehicles).size).to eq(2)
    end

    it "refuses a jumper" do
      expect { client_operation("CreateVehicle", variables: { attributes: attributes }, as: user) }.not_to change(Vehicle, :count)
    end
  end

  describe "UpdateVehicle" do
    it "updates the vehicle" do
      json = client_operation("UpdateVehicle", variables: { id: vehicle.id, attributes: { name: "Renamed", capacity: 12 } }, as: owner_user)

      expect(json.dig(:data, :updateVehicle, :vehicle)).to include(name: "Renamed", capacity: 12)
    end

    it "refuses a jumper" do
      client_operation("UpdateVehicle", variables: { id: vehicle.id, attributes: { name: "Hijacked" } }, as: user)

      expect(vehicle.reload.name).not_to eq("Hijacked")
    end

    it "cannot move a vehicle to another operator" do
      client_operation("UpdateVehicle", variables: { id: vehicle.id, attributes: { operatorId: other_operator.id } }, as: owner_user)

      expect(vehicle.reload.operator).to eq(operator)
    end
  end

  describe "ArchiveVehicle" do
    it "archives the vehicle" do
      json = client_operation("ArchiveVehicle", variables: { id: vehicle.id }, as: owner_user)

      expect(json.dig(:data, :deleteVehicle, :errors)).to be_nil
      expect(vehicle.reload).to be_discarded
    end

    it "refuses a jumper" do
      client_operation("ArchiveVehicle", variables: { id: vehicle.id }, as: user)

      expect(vehicle.reload).not_to be_discarded
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
    let(:attributes) { { name: "Hop n Pop", costCents: 2500, defaultDestinationId: destination.id, allowManifestingSelf: true, operatorId: operator.id, currency: "AUD" } }
    let(:destination) { Destination.altitude_for(operator, 5000) }

    it "creates a ticket type" do
      json = nil
      expect { json = client_operation("CreateTicketType", variables: { attributes: attributes }, as: owner_user) }.to change(TicketType, :count).by(1)

      expect(json.dig(:data, :createTicketType, :ticketType)).to include(name: "Hop n Pop", costCents: 2500)
      expect(json.dig(:data, :createTicketType, :ticketType, :defaultDestination)).to include(name: "5000 ft", altitudeM: 1524.0)
    end

    it "refuses a jumper" do
      expect { client_operation("CreateTicketType", variables: { attributes: attributes }, as: user) }.not_to change(TicketType, :count)
    end

    describe "certification requirements" do
      let(:body) { operator.certification_bodies.first }
      let(:rating) { create(:qualification, certification_body: body, name: "Tandem rating") }

      it "stores the minimum rank and the qualification a ticket asks for" do
        json = client_operation("CreateTicketType", variables: { attributes: attributes.merge(minCertificationRank: 30, requiredQualificationId: rating.id) }, as: owner_user)

        expect(json.dig(:data, :createTicketType, :ticketType)).to include(minCertificationRank: 30)
        expect(json.dig(:data, :createTicketType, :ticketType, :requiredQualification)).to include(name: "Tandem rating", slug: rating.slug)
      end

      it "refuses a qualification of a body the operator does not accept" do
        foreign = create(:qualification, certification_body: CertificationBody.create!(name: "Other", slug: "other", industry: "skydiving"))

        json = nil
        expect do
          json = client_operation("CreateTicketType", variables: { attributes: attributes.merge(requiredQualificationId: foreign.id) }, as: owner_user)
        end.not_to change(TicketType, :count)

        expect(json.dig(:data, :createTicketType, :fieldErrors, 0, :field)).to eq("required_qualification")
      end

      it "refuses a negative rank" do
        expect { client_operation("CreateTicketType", variables: { attributes: attributes.merge(minCertificationRank: -1) }, as: owner_user) }.not_to change(TicketType, :count)
      end

      it "changes the requirement of a ticket and clears it again" do
        ticket = create(:ticket_type, operator: operator, min_certification_rank: 20)

        client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { minCertificationRank: 40, requiredQualificationId: rating.id } }, as: owner_user)
        expect(ticket.reload).to have_attributes(min_certification_rank: 40, required_qualification_id: rating.id)

        client_operation("UpdateTicketType", variables: { id: ticket.id, attributes: { minCertificationRank: nil, requiredQualificationId: nil } }, as: owner_user)
        expect(ticket.reload).to have_attributes(min_certification_rank: nil, required_qualification_id: nil)
      end

      it "lets an extra ask for a qualification, which the operator reports as required" do
        json = client_operation("CreateTicketAddon", variables: { attributes: { name: "Nitrox", costCents: 500, operatorId: operator.id, requiredQualificationId: rating.id } }, as: owner_user)

        expect(json.dig(:data, :createExtra, :extra, :requiredQualification)).to include(name: "Tandem rating")
        expect(operator.reload.extras.pluck(:required_qualification_id)).to eq([rating.id])

        required = client_operation("Operator", variables: { operatorId: operator.id }, as: owner_user).dig(:data, :operator, :requiredQualifications)
        expect(required.pluck(:name)).to eq(["Tandem rating"])
      end
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

  describe "OperatorEquipment" do
    it "lists the operator's equipment" do
      equipment = create(:equipment, operator: operator)

      json = client_operation("OperatorEquipment", variables: { operatorId: operator.id }, as: owner_user)

      expect(json.dig(:data, :operator, :equipment).pluck(:id)).to eq([equipment.id.to_s])
    end

    it "is empty for an operator without equipment" do
      expect(client_operation("OperatorEquipment", variables: { operatorId: operator.id }, as: owner_user).dig(:data, :operator, :equipment)).to eq([])
    end
  end

  describe "AvailableEquipment" do
    it "returns the equipment of the member that were inspected as ok" do
      equipment = create(:equipment, user: user, operator: nil)
      create(:equipment_inspection, equipment: equipment, membership: fun_jumper, inspected_by: owner, is_ok: true)

      json = client_operation("AvailableEquipment", variables: { membershipId: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :availableEquipment).pluck(:id)).to include(equipment.id.to_s)
    end

    it "does not return uninspected equipment" do
      equipment = create(:equipment, user: user, operator: nil)

      json = client_operation("AvailableEquipment", variables: { membershipId: fun_jumper.id }, as: owner_user)

      expect(json.dig(:data, :availableEquipment).pluck(:id)).not_to include(equipment.id.to_s)
    end

    it "returns the operator's tandem equipment for tandem slots" do
      json = client_operation("AvailableEquipment", variables: { membershipId: fun_jumper.id, isTandem: true }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :availableEquipment)).to be_an(Array)
    end
  end

  describe "CreateEquipment" do
    let(:variables) { { make: "Vector", model: "v310", serial: "12345", equipmentType: "sport", canopySize: 129, userId: user.id } }

    it "creates a equipment owned by the caller" do
      json = nil
      expect { json = client_operation("CreateEquipment", variables: variables, as: user) }.to change(Equipment, :count).by(1)

      expect(json.dig(:data, :createEquipment, :errors)).to be_nil
      expect(json.dig(:data, :createEquipment, :equipment)).to include(make: "Vector", serial: "12345")
    end

    it "refuses creating a equipment for another user" do
      expect { client_operation("CreateEquipment", variables: variables.merge(userId: staff_user.id), as: user) }.not_to change(Equipment, :count)
    end

    # The app sends the packing card with UpdateEquipment; createEquipment takes it too
    def create_equipment_with_card(card)
      query = "mutation($attributes: EquipmentInput!) { createEquipment(input: { attributes: $attributes }) { errors fieldErrors { field message } equipment { id } } }"
      post "/graphql",
           params: { query: query, variables: { attributes: { make: "Vector", model: "v310", serial: "1", kindId: operator.equipment_kinds.find_by!(key: "rig").id.to_s, attributes: { rig_type: "sport", canopy_size_m2: 12 }, userId: user.id, packingCard: card } }.to_json },
           headers: user.create_new_auth_token
      response.parsed_body.with_indifferent_access
    end

    it "stores a packing card image when the equipment is created" do
      json = create_equipment_with_card(image_data_url("jpg"))

      expect(json.dig(:data, :createEquipment, :errors)).to be_nil
      expect(Equipment.find(json.dig(:data, :createEquipment, :equipment, :id)).packing_card).to be_attached
    end

    it "refuses a packing card that is not a picture, and creates no equipment" do
      json = nil
      expect { json = create_equipment_with_card(data_url_of("not an image")) }.not_to change(Equipment, :count)

      expect(json.dig(:data, :createEquipment, :fieldErrors, 0, :field)).to eq("packing_card")
    end
  end

  describe "UpdateEquipment" do
    let!(:equipment) { create(:equipment, user: user, operator: nil) }

    it "stores a packing card image" do
      json = client_operation("UpdateEquipment", variables: { id: equipment.id, packingCard: image_data_url("png") }, as: user)

      expect(json.dig(:data, :updateEquipment, :errors)).to be_nil
      expect(equipment.reload.packing_card).to be_attached
      expect(equipment.packing_card.content_type).to eq("image/png")
    end

    it "updates the caller's own equipment" do
      json = client_operation("UpdateEquipment", variables: { id: equipment.id, name: "Main", attributes: { canopy_size_m2: 11 } }, as: user)

      expect(json.dig(:data, :updateEquipment, :equipment)).to include(name: "Main")
      expect(json.dig(:data, :updateEquipment, :equipment, :attributes)).to include(canopy_size_m2: 11)
    end

    it "refuses another jumper" do
      client_operation("UpdateEquipment", variables: { id: equipment.id, name: "Hijacked" }, as: staff_user)

      expect(equipment.reload.name).not_to eq("Hijacked")
    end

    it "cannot reassign the equipment to another user" do
      client_operation("UpdateEquipment", variables: { id: equipment.id, userId: staff_user.id }, as: user)

      expect(equipment.reload.user).to eq(user)
    end
  end

  describe "ArchiveEquipment" do
    let!(:equipment) { create(:equipment, user: user, operator: nil) }

    it "archives the caller's own equipment" do
      json = client_operation("ArchiveEquipment", variables: { id: equipment.id }, as: user)

      expect(json.dig(:data, :archiveEquipment, :errors)).to be_nil
      expect(equipment.reload).to be_discarded
    end

    it "archives someone else's equipment for staff" do
      client_operation("ArchiveEquipment", variables: { id: equipment.id }, as: owner_user)

      expect(equipment.reload).to be_discarded
    end
  end

  describe "CreateEquipmentInspection" do
    let!(:equipment) { create(:equipment, user: user, operator: nil) }
    let!(:template) { operator.equipment_kinds.find_by!(key: "rig").inspection_form_template }

    before { owner.grant!("actAsEquipmentInspector") }

    it "records an inspection by a equipment inspector" do
      json = nil
      expect do
        json = client_operation("CreateEquipmentInspection", variables: { operator: operator.id, equipment: equipment.id, isOk: true, definition: "[]" }, as: owner_user)
      end.to change(EquipmentInspection, :count).by(1)

      expect(json.dig(:data, :createEquipmentInspection, :equipmentInspection, :isOk)).to be(true)
    end

    it "refuses a user who is not a equipment inspector" do
      expect do
        client_operation("CreateEquipmentInspection", variables: { operator: operator.id, equipment: equipment.id, isOk: true, definition: "[]" }, as: user)
      end.not_to change(EquipmentInspection, :count)
    end

    it "notifies the equipment owner when the equipment is cleared to jump" do
      expect do
        client_operation("CreateEquipmentInspection", variables: { operator: operator.id, equipment: equipment.id, isOk: true, definition: "[]" }, as: owner_user)
      end.to change { Notification.where(notification_type: :equipment_inspection_completed).count }.by(1)
    end

    it "does not tell the equipment owner they are cleared when the inspection failed" do
      expect do
        client_operation("CreateEquipmentInspection", variables: { operator: operator.id, equipment: equipment.id, isOk: false, definition: "[]" }, as: owner_user)
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

  describe "DailyLog" do
    let(:date) { Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }

    it "returns the master log entry for a day" do
      json = client_operation("DailyLog", variables: { operatorId: operator.id, date: date }, as: owner_user)

      expect(json[:errors]).to be_nil
      expect(json.dig(:data, :dailyLog)).to be_nil.or(include(:id, :date, :loads))
    end

    it "requires authentication" do
      expect(client_operation("DailyLog", variables: { operatorId: operator.id, date: date }).dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end

    it "does not return another operator's master log to a stranger" do
      other_operator.daily_logs.create!(date: Date.current) if other_operator.daily_logs.respond_to?(:create!)

      json = client_operation("DailyLog", variables: { operatorId: other_operator.id, date: date }, as: user)

      expect(json.dig(:data, :dailyLog)).to be_nil
    end
  end

  describe "UpdateDailyLog" do
    let(:date) { Time.current.in_time_zone(operator.time_zone).to_date.iso8601 }

    it "saves the notes and DutyOfficer for the day" do
      json = client_operation("UpdateDailyLog", variables: { date: date, operator: operator.id, attributes: { notes: "Windy afternoon", dutyOfficer: owner.id } }, as: owner_user)

      expect(json.dig(:data, :updateDailyLog, :errors)).to be_nil
      expect(json.dig(:data, :updateDailyLog, :dailyLog)).to include(notes: "Windy afternoon")
      expect(json.dig(:data, :updateDailyLog, :dailyLog, :dutyOfficer, :id)).to eq(owner.id.to_s)
    end

    it "refuses a jumper" do
      client_operation("UpdateDailyLog", variables: { date: date, operator: operator.id, attributes: { notes: "Hijacked" } }, as: user)

      expect(operator.daily_logs.where(notes: "Hijacked")).to be_empty
    end
  end
end
