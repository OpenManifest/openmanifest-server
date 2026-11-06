# frozen_string_literal: true

# P7.5 (D5: rename in place): Plane becomes Vehicle, Passenger becomes Guest, JumpType becomes ActivityType, MasterLog
# becomes DailyLog, exit weight becomes body mass in kg, jump counts become load counts, and vehicles get a kind. Also the
# class names that polymorphic columns store. Reversible.
class RenameAviationNamesToGeneric < ActiveRecord::Migration[8.1]
  TABLES = {
    planes: :vehicles,
    passengers: :guests,
    jump_types: :activity_types,
    licensed_jump_types: :licensed_activity_types,
    master_logs: :daily_logs,
  }.freeze
  # [table (new name), old column, new column]
  COLUMNS = [
    [:loads, :plane_id, :vehicle_id],
    [:slots, :jump_type_id, :activity_type_id],
    [:licensed_activity_types, :jump_type_id, :activity_type_id],
    [:slots, :passenger_id, :guest_id],
    [:slots, :passenger_slot_id, :guest_slot_id],
    [:daily_logs, :dzso_id, :duty_officer_id],
    [:users, :exit_weight, :body_mass_kg],
    [:slots, :exit_weight, :body_mass_kg],
    [:guests, :exit_weight, :body_mass_kg],
    [:users, :jump_count, :load_count],
    [:memberships, :jump_count, :load_count],
    [:vehicles, :max_slots, :capacity],
    [:vehicles, :min_slots, :min_capacity],
  ].freeze
  POLYMORPHIC = {
    active_storage_attachments: %i(record_type),
    events: %i(resource_type),
    notifications: %i(resource_type),
    orders: %i(seller_type buyer_type item_type),
    transactions: %i(sender_type receiver_type),
  }.freeze
  CLASSES = {
    "LicensedJumpType" => "LicensedActivityType",
    "JumpType" => "ActivityType",
    "MasterLog" => "DailyLog",
    "Passenger" => "Guest",
    "Plane" => "Vehicle",
  }.freeze

  def up
    TABLES.each { |from, to| rename_table from, to }
    COLUMNS.each { |table, from, to| rename_column table, from, to }
    remove_column :users, :plane_count
    add_column :vehicles, :kind, :string, null: false, default: "aircraft"
    rename_classes(CLASSES)
  end

  def down
    rename_classes(CLASSES.invert)
    remove_column :vehicles, :kind
    add_column :users, :plane_count, :integer, default: 0, null: false
    COLUMNS.reverse_each { |table, from, to| rename_column table, to, from }
    TABLES.reverse_each { |from, to| rename_table to, from }
  end

  private

  def rename_classes(mapping)
    POLYMORPHIC.each do |table, columns|
      columns.each do |column|
        mapping.each { |from, to| execute "UPDATE #{table} SET #{column} = #{quote(to)} WHERE #{column} = #{quote(from)}" }
      end
    end
  end
end
