# frozen_string_literal: true

require "rails_helper"

# The conditions panel of the board (U5.7): the temperature, the jump run heading and the winds aloft, in SI
RSpec.describe "Client operations: conditions" do
  include_context "operator"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:membership, operator: operator, user: owner_user, user_role: operator.user_roles.find_by(name: "owner")) }
  let!(:conditions) { operator.current_conditions }
  let(:winds) do
    [
      { altitude_m: 609.6, speed_mps: 2.57, direction: 180 },
      { altitude_m: 4267.2, speed_mps: 10.29, direction: 250, temperature_c: -12 },
    ]
  end
  let(:variables) { { id: conditions.id, operatorId: operator.id, winds: winds.to_json, temperatureC: 21.1, jumpRun: 275 } }

  describe "SaveConditions" do
    it "saves the conditions of the day and answers with them" do
      json = client_operation("SaveConditions", variables: variables, as: owner_user)
      payload = json.dig(:data, :createWeatherCondition)

      expect(payload[:errors]).to be_nil
      expect(payload.dig(:weatherCondition, :id)).to eq(conditions.id.to_s)
      expect(payload.dig(:weatherCondition, :jumpRun)).to eq(275)
      expect(payload.dig(:weatherCondition, :temperatureC)).to eq(21.1)
      expect(payload.dig(:weatherCondition, :winds)).to contain_exactly(
        { temperatureC: nil, altitudeM: 609.6, speedMps: 2.57, direction: 180 },
        { temperatureC: -12.0, altitudeM: 4267.2, speedMps: 10.29, direction: 250 }
      )
      expect(conditions.reload.jump_run).to eq(275)
    end

    it "shows the saved conditions as the operator's current ones" do
      client_operation("SaveConditions", variables: variables, as: owner_user)

      expect(operator.reload.current_conditions.wind_list.size).to eq(2)
      expect(operator.current_conditions.temperature_c).to eq(21.1)
    end

    it "does not let a jumper change the conditions" do
      json = client_operation("SaveConditions", variables: variables, as: user)

      expect(json.dig(:data, :createWeatherCondition, :errors)).to eq(["You can't update weather conditions"])
      expect(conditions.reload.jump_run).to be_nil
    end

    it "does not change another operator's conditions through one's own" do
      other_operator = create(:operator, state: "public")
      foreign = other_operator.current_conditions

      json = client_operation("SaveConditions", variables: variables.merge(id: foreign.id), as: owner_user)

      expect(json.dig(:data, :createWeatherCondition, :weatherCondition)).to be_nil
      expect(json.dig(:data, :createWeatherCondition, :errors).first).to match(/Couldn't find WeatherCondition/)
      expect(foreign.reload.jump_run).to be_nil
    end
  end
end
