# frozen_string_literal: true

RSpec.shared_context "dropzone_with_manifested_loads", shared_context: :metadata do
  include_context 'dropzone_with_load'
  let!(:access_context) do
    instructor.grant! :createSlot
    instructor.grant! :createUserSlot
    ApplicationInteraction::AccessContext.new(instructor)
  end
  let!(:ticket_type) { create(:ticket_type, dropzone: dropzone) }
  let!(:load2) { create(:load, plane: plane, pilot: pilot, gca: gca) }
  let!(:jumpers) do
    create_list(
      :dropzone_user,
      10,
      dropzone: dropzone,
      credits: ticket_type.cost * 2
    )
  end

  # Manifest users on these loads
  let!(:slots) do
    jumpers.filter_map do |jumper|
      Manifest::CreateSlot.run!(
        access_context: access_context,
        ticket_type: ticket_type,
        dropzone_user: jumper,
        jump_type: JumpType.allowed_for([jumper]).sample,
        load: [load, load2].sample,
        exit_weight: jumper.exit_weight
      )
    end
  end
end
