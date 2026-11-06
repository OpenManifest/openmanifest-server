# frozen_string_literal: true

# P7.16 (GENERALISATION §11): the data the `limits` rules need. A user's date of birth (a guest has one since P7.15); limits
# on who a ticket type or an activity takes (`min_age`, `max_age`, `min_body_mass_kg`, `max_body_mass_kg`), limits on a
# flight group of a ticket type (`max_group_body_mass_kg`, `max_group_size`), and what a vehicle may carry.
class AddParticipantLimits < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :date_of_birth, :date
    add_column :ticket_types, :participant_limits, :jsonb, null: false, default: {}
    add_column :ticket_types, :group_limits, :jsonb, null: false, default: {}
    add_column :activity_types, :participant_limits, :jsonb, null: false, default: {}
    add_column :vehicles, :max_payload_kg, :decimal, precision: 8, scale: 2
  end
end
