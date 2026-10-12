# frozen_string_literal: true

require "rails_helper"

# P7.9 through the API: the vehicles of a load, the slots in them
RSpec.describe "Load vehicles" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner"), credits: 500) }
  let!(:pilot) { create(:membership, operator: operator) }
  let!(:big) { create(:vehicle, operator: operator, capacity: 6, min_capacity: 1) }
  let!(:small) { create(:vehicle, operator: operator, capacity: 3, min_capacity: 1) }
  let!(:tug) { create(:vehicle, operator: operator, capacity: 1, kind: "tug") }

  let(:load_fields) { "id maxSlots availableSlots vehicle { id } vehicles { id role position capacity slotsCount vehicle { id name } }" }
  let(:create_load) do
    "mutation($attributes: LoadInput!) { createLoad(input: { attributes: $attributes }) { errors load { #{load_fields} } } }"
  end
  let(:update_load) do
    "mutation($id: ID!, $attributes: LoadInput!) { updateLoad(input: { id: $id, attributes: $attributes }) { errors load { #{load_fields} } } }"
  end

  def graphql(query, variables = {}, as: owner_user)
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  def new_load(**attrs)
    graphql(create_load, { attributes: { gca: owner.id, pilot: pilot.id }.merge(attrs) })
  end

  context "with the multi_vehicle module" do
    before { operator.update!(modules: { multi_vehicle: true }) }

    it "creates a load with several vehicles, the seats added up" do
      json = new_load(vehicles: [{ vehicleId: big.id }, { vehicleId: small.id }, { vehicleId: tug.id, role: "support" }])

      load = json.dig(:data, :createLoad, :load)
      expect(json.dig(:data, :createLoad, :errors)).to be_nil
      expect(load[:maxSlots]).to eq(9)
      expect(load[:vehicles].pluck(:role)).to eq(%w(carrying carrying support))
      expect(load[:vehicles].pluck(:capacity)).to eq([6, 3, 0])
      expect(load.dig(:vehicle, :id)).to eq(big.id.to_s)
    end

    it "changes the vehicles of a load and the seats with them" do
      id = new_load(vehicles: [{ vehicleId: big.id }]).dig(:data, :createLoad, :load, :id)

      json = graphql(update_load, { id: id, attributes: { vehicles: [{ vehicleId: big.id }, { vehicleId: small.id }] } })

      expect(json.dig(:data, :updateLoad, :load, :maxSlots)).to eq(9)
      expect(json.dig(:data, :updateLoad, :load, :vehicles).size).to eq(2)
    end

    it "does not take a vehicle off a load while jumpers ride in it" do
      id = new_load(vehicles: [{ vehicleId: big.id }, { vehicleId: small.id }]).dig(:data, :createLoad, :load, :id)
      load = Load.find(id)
      member = create(:membership, operator: operator, credits: 500)
      Slot.create!(load: load, membership: member, ticket_type: create(:ticket_type, operator: operator), body_mass_kg: 80,
                   created_by: member, activity_type: ActivityType.allowed_for([member]).first,
                   load_vehicle: load.load_vehicles.find_by!(vehicle: small))

      json = graphql(update_load, { id: id, attributes: { vehicles: [{ vehicleId: big.id }] } })

      expect(json.dig(:data, :updateLoad, :errors).join).to include("cannot be taken off the load")
      expect(load.reload.vehicles).to contain_exactly(big, small)
    end

    it "refuses a load with only a support vehicle" do
      json = new_load(vehicles: [{ vehicleId: tug.id, role: "support" }])

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json.dig(:data, :createLoad, :errors).join).to include("needs a vehicle that carries")
    end

    describe "slots in a vehicle" do
      let(:load) { Load.find(new_load(vehicles: [{ vehicleId: big.id }, { vehicleId: small.id }]).dig(:data, :createLoad, :load, :id)) }
      let(:small_row) { load.load_vehicles.find_by!(vehicle: small) }
      let(:big_row) { load.load_vehicles.find_by!(vehicle: big) }
      let(:member) { create(:membership, operator: operator, credits: 500) }
      let(:ticket) { create(:ticket_type, operator: operator) }
      let(:create_slot) do
        "mutation($attributes: SlotInput!) { createSlot(input: { attributes: $attributes }) { errors slot { id loadVehicle { id slotsCount } } } }"
      end
      let(:move_slot) do
        "mutation($source: Int!, $load: Int!, $vehicle: Int) { moveSlot(input: { sourceSlot: $source, targetLoad: $load, targetLoadVehicle: $vehicle }) { errors loads { id vehicles { id slotsCount } } } }"
      end

      def manifest(row, who: member)
        graphql(create_slot, { attributes: {
          load: load.id, membership: who.id, ticketType: ticket.id, loadVehicle: row&.id, bodyMassKg: 80,
          activityType: ActivityType.allowed_for([who]).first.id
        }.compact })
      end

      it "puts a jumper in a vehicle and counts them there" do
        json = manifest(small_row)

        expect(json.dig(:data, :createSlot, :errors)).to be_nil
        expect(json.dig(:data, :createSlot, :slot, :loadVehicle)).to include(id: small_row.id.to_s, slotsCount: 1)
      end

      it "refuses a jumper when the vehicle is full although the load has room" do
        3.times { manifest(small_row, who: create(:membership, operator: operator, credits: 500)) }

        json = manifest(small_row)

        expect(json.dig(:data, :createSlot, :slot)).to be_nil
        expect(json.dig(:data, :createSlot, :errors).join).to include("No slots available in #{small.name}")
        expect(load.reload.slots_count).to eq(3)
      end

      it "moves a jumper to the other vehicle of the load" do
        slot_id = manifest(small_row).dig(:data, :createSlot, :slot, :id)

        json = graphql(move_slot, { source: slot_id.to_i, load: load.id, vehicle: big_row.id })

        expect(json.dig(:data, :moveSlot, :errors)).to be_nil
        counts = json.dig(:data, :moveSlot, :loads, 0, :vehicles).to_h { |v| [v[:id], v[:slotsCount]] }
        expect(counts).to eq(small_row.id.to_s => 0, big_row.id.to_s => 1)
      end

      it "takes a moved jumper out of the vehicle it rode in when the load changes" do
        slot_id = manifest(small_row).dig(:data, :createSlot, :slot, :id)
        other = Load.find(new_load(vehicles: [{ vehicleId: big.id }]).dig(:data, :createLoad, :load, :id))

        graphql(move_slot, { source: slot_id.to_i, load: other.id })

        expect(Slot.find(slot_id)).to have_attributes(load_id: other.id, load_vehicle_id: nil)
        expect(small_row.reload.slots_count).to eq(0)
      end
    end
  end

  context "without the module (skydiving)" do
    it "still takes the vehicle alone" do
      json = new_load(vehicle: big.id)

      expect(json.dig(:data, :createLoad, :load, :vehicles).size).to eq(1)
      expect(json.dig(:data, :createLoad, :load, :maxSlots)).to eq(6)
    end

    it "refuses several vehicles" do
      json = new_load(vehicles: [{ vehicleId: big.id }, { vehicleId: small.id }])

      expect(json.dig(:data, :createLoad, :load)).to be_nil
      expect(json.dig(:data, :createLoad, :errors).join).to include("has one vehicle")
    end
  end
end
