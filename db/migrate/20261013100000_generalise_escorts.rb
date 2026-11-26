# frozen_string_literal: true

# P7.15 (GENERALISATION §10): tandem becomes "requires an escort". A ticket type that requires an escort takes up to
# `escort_capacity` guests for each escort (tandem: one; a try dive: four), the escort optionally needs a qualification
# or a crew role's permission. The guest's slot points to the escort's slot (`escort_slot_id`; it was the other way round,
# one `guest_slot_id` on the escort's slot), and a guest carries the personal fields of a booking participant. Reversible:
# going back keeps the first guest of each escort.
class GeneraliseEscorts < ActiveRecord::Migration[8.1]
  def up
    rename_column :ticket_types, :is_tandem, :requires_escort
    add_column :ticket_types, :escort_capacity, :integer, null: false, default: 1
    add_reference :ticket_types, :escort_qualification, foreign_key: { to_table: :qualifications }
    add_reference :ticket_types, :escort_crew_role, foreign_key: { to_table: :crew_roles }

    add_reference :slots, :escort_slot, foreign_key: { to_table: :slots }
    execute <<~SQL.squish
      UPDATE slots AS guest SET escort_slot_id = escort.id
      FROM slots AS escort WHERE escort.guest_slot_id = guest.id
    SQL
    remove_reference :slots, :guest_slot, foreign_key: { to_table: :slots }, index: true

    add_column :guests, :email, :string
    add_column :guests, :phone, :string
    add_column :guests, :date_of_birth, :date
    add_column :guests, :emergency_contact, :string
  end

  def down
    remove_column :guests, :emergency_contact
    remove_column :guests, :date_of_birth
    remove_column :guests, :phone
    remove_column :guests, :email

    add_reference :slots, :guest_slot, foreign_key: { to_table: :slots }
    execute <<~SQL.squish
      UPDATE slots AS escort SET guest_slot_id = first_guest.id
      FROM (SELECT DISTINCT ON (escort_slot_id) id, escort_slot_id FROM slots WHERE escort_slot_id IS NOT NULL ORDER BY escort_slot_id, id) AS first_guest
      WHERE escort.id = first_guest.escort_slot_id
    SQL
    remove_reference :slots, :escort_slot, foreign_key: { to_table: :slots }, index: true

    remove_reference :ticket_types, :escort_crew_role, foreign_key: { to_table: :crew_roles }
    remove_reference :ticket_types, :escort_qualification, foreign_key: { to_table: :qualifications }
    remove_column :ticket_types, :escort_capacity
    rename_column :ticket_types, :requires_escort, :is_tandem
  end
end
