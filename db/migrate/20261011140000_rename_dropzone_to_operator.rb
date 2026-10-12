# frozen_string_literal: true

# P7.3 (D5: rename in place): Dropzone becomes Operator and DropzoneUser becomes Membership, in the tables, in every
# column that points at them and in the class names that polymorphic columns store. rename_table and rename_column
# rename the sequences and the default-named indexes with them. Reversible: the data examples of the earlier migrations
# (spec/migrations) go back to the old schema through `down`.
class RenameDropzoneToOperator < ActiveRecord::Migration[8.1]
  DROPZONE_ID = %i(
    events extras form_templates loads master_logs orders passengers planes rigs ticket_types user_roles
    weather_conditions
  ).freeze
  DROPZONE_USER_ID = %i(events rig_inspections slots user_permissions).freeze
  # [table, polymorphic type columns]
  POLYMORPHIC = {
    active_storage_attachments: %i(record_type),
    events: %i(resource_type),
    notifications: %i(resource_type),
    orders: %i(seller_type buyer_type item_type),
    transactions: %i(sender_type receiver_type),
  }.freeze
  CLASSES = { "DropzoneUser" => "Membership", "Dropzone" => "Operator" }.freeze

  def up
    rename_schema
    rename_classes(CLASSES)
  end

  def down
    rename_classes(CLASSES.invert)
    rename_schema(reverse: true)
  end

  private

  def rename_schema(reverse: false)
    if reverse
      rename_column :users, :operator_count, :dropzone_count
      DROPZONE_USER_ID.each { |table| rename_column table, :membership_id, :dropzone_user_id }
      DROPZONE_ID.each { |table| rename_column table, :operator_id, :dropzone_id }
      rename_column :memberships, :operator_id, :dropzone_id
      rename_table :memberships, :dropzone_users
      rename_table :operators, :dropzones
    else
      rename_table :dropzones, :operators
      rename_table :dropzone_users, :memberships
      rename_column :memberships, :dropzone_id, :operator_id
      DROPZONE_ID.each { |table| rename_column table, :dropzone_id, :operator_id }
      DROPZONE_USER_ID.each { |table| rename_column table, :dropzone_user_id, :membership_id }
      rename_column :users, :dropzone_count, :operator_count
    end
  end

  def rename_classes(mapping)
    POLYMORPHIC.each do |table, columns|
      columns.each do |column|
        mapping.each { |from, to| execute "UPDATE #{table} SET #{column} = #{quote(to)} WHERE #{column} = #{quote(from)}" }
      end
    end
  end
end
