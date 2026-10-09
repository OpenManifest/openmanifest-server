# frozen_string_literal: true

require "rails_helper"

# BUG-029: updateSlot compared the caller with `slot.user_id`, which does not exist, so it raised for everybody.
RSpec.describe "updateSlot" do
  let(:dropzone) { create(:dropzone, credits: 50, state: "public") }
  let(:other_dropzone) { create(:dropzone, credits: 50, state: "public") }
  let(:plane) { create(:plane, dropzone: dropzone, max_slots: 14) }
  let(:ticket_type) { create(:ticket_type, dropzone: dropzone, name: "Height", cost: 40) }
  let(:other_ticket_type) { create(:ticket_type, dropzone: other_dropzone, name: "Height", cost: 40) }
  let(:plane_load) { create(:load, plane: plane) }
  let(:other_load) { create(:load, plane: plane) }

  let(:jumper_user) { create(:user) }
  let!(:jumper) { create(:dropzone_user, dropzone: dropzone, user: jumper_user, user_role: dropzone.user_roles.find_by(name: "fun_jumper"), credits: 300) }
  let(:staff_user) { create(:user) }
  let!(:staff) { create(:dropzone_user, dropzone: dropzone, user: staff_user, user_role: dropzone.user_roles.find_by(name: "manifest"), credits: 300) }
  let(:stranger_user) { create(:user) }
  let!(:stranger) { create(:dropzone_user, dropzone: dropzone, user: stranger_user, user_role: dropzone.user_roles.find_by(name: "fun_jumper"), credits: 300) }
  let!(:slot) do
    create(:slot, load: plane_load, dropzone: dropzone, dropzone_user: jumper, ticket_type: ticket_type, exit_weight: 80,
                  jump_type: JumpType.allowed_for([jumper]).first, created_by: staff)
  end

  let(:query) do
    "mutation($id: Int!, $attributes: SlotInput!) { updateSlot(input: { id: $id, attributes: $attributes }) { slot { id exitWeight } errors } }"
  end

  def update_slot(attributes, as:, id: slot.id)
    post "/graphql", params: { query: query, variables: { id: id, attributes: attributes }.to_json }, headers: as.create_new_auth_token
    response.parsed_body.with_indifferent_access
  end

  before do
    # The fun jumper role may edit their own slot
    jumper.grant!(:updateSlot)
  end

  it "lets a member edit their own slot" do
    json = update_slot({ exitWeight: 85 }, as: jumper_user)

    expect(json.dig(:data, :updateSlot, :errors)).to be_nil
    expect(slot.reload.exit_weight).to eq(85)
  end

  it "lets staff with updateUserSlot edit somebody else's slot" do
    json = update_slot({ exitWeight: 90 }, as: staff_user)

    expect(json.dig(:data, :updateSlot, :errors)).to be_nil
    expect(slot.reload.exit_weight).to eq(90)
  end

  it "refuses another member" do
    json = update_slot({ exitWeight: 99 }, as: stranger_user)

    expect(json.dig(:data, :updateSlot, :slot)).to be_nil
    expect(slot.reload.exit_weight).to eq(80)
  end

  it "refuses a member of another dropzone" do
    outsider = create(:user)
    create(:dropzone_user, dropzone: other_dropzone, user: outsider, user_role: other_dropzone.user_roles.find_by(name: "owner"))

    update_slot({ exitWeight: 99 }, as: outsider)

    expect(slot.reload.exit_weight).to eq(80)
  end

  it "answers an unknown slot with an error instead of raising" do
    json = update_slot({ exitWeight: 99 }, as: staff_user, id: 0)

    expect(json.dig(:data, :updateSlot, :slot)).to be_nil
  end

  it "does not move the slot to another load or person" do
    update_slot({ load: other_load.id, dropzoneUser: stranger.id, exitWeight: 82 }, as: staff_user)

    expect(slot.reload.load).to eq(plane_load)
    expect(slot.dropzone_user).to eq(jumper)
    expect(slot.exit_weight).to eq(82)
  end

  it "refuses a ticket type of another dropzone" do
    json = update_slot({ ticketType: other_ticket_type.id }, as: staff_user)

    expect(json.dig(:data, :updateSlot, :errors).join).to match(/same dropzone/)
    expect(slot.reload.ticket_type).to eq(ticket_type)
  end
end
