# frozen_string_literal: true

# A person has one membership per dropzone (BUG-050; the model validates it, which concurrent requests get around).
# Duplicates, which the old auto-created memberships could produce when two requests raced, are merged into one first: the
# kept membership (the oldest if several are kept), everything that pointed at a duplicate points at it, credits and jump
# counts are added up, and the duplicates are deleted. Counts and ids are printed.
#
# Leaving a dropzone discards the membership; joining again restores it (Users::JoinDropzone).
class AddUniqueIndexToDropzoneUsersOnUserAndDropzone < ActiveRecord::Migration[8.1]
  INDEX = "index_dropzone_users_on_user_id_and_dropzone_id"

  # Columns that reference dropzone_users.id, [table, column]
  REFERENCES = [
    %w(events dropzone_user_id),
    %w(form_templates created_by_id),
    %w(form_templates updated_by_id),
    %w(loads gca_id),
    %w(loads load_master_id),
    %w(loads pilot_id),
    %w(master_logs dzso_id),
    %w(notifications received_by_id),
    %w(notifications sent_by_id),
    %w(rig_inspections dropzone_user_id),
    %w(rig_inspections inspected_by_id),
    %w(slots created_by_id),
  ].freeze

  # Polymorphic references, [table, column prefix]
  POLYMORPHIC = [
    %w(orders buyer),
    %w(orders seller),
    %w(transactions sender),
    %w(transactions receiver),
    %w(events resource),
    %w(notifications resource),
  ].freeze

  def up
    merge_duplicate_memberships

    add_index :dropzone_users, [:user_id, :dropzone_id], unique: true, name: INDEX
  end

  def down
    remove_index :dropzone_users, name: INDEX
  end

  def merge_duplicate_memberships
    groups = select_rows(<<~SQL.squish)
      SELECT user_id, dropzone_id, ARRAY_AGG(id ORDER BY (discarded_at IS NULL) DESC, created_at, id)
      FROM dropzone_users
      GROUP BY user_id, dropzone_id
      HAVING COUNT(*) > 1
    SQL
    say "Merging #{groups.size} duplicate membership group(s)"

    groups.each do |user_id, dropzone_id, ids|
      ids = ids.delete("{}").split(",") if ids.is_a?(String)
      keeper, *duplicates = ids.map(&:to_i)
      say "user #{user_id} at dropzone #{dropzone_id}: keeping #{keeper}, merging #{duplicates.inspect}", true
      merge_into(keeper, duplicates)
    end
  end

  private

  def merge_into(keeper, duplicates)
    list = duplicates.join(",")

    execute "UPDATE dropzone_users SET credits = COALESCE(credits, 0) + (SELECT COALESCE(SUM(credits), 0) FROM dropzone_users WHERE id IN (#{list})) WHERE id = #{keeper} AND EXISTS (SELECT 1 FROM dropzone_users WHERE id IN (#{list}) AND credits IS NOT NULL)"
    execute "UPDATE dropzone_users SET jump_count = jump_count + (SELECT COALESCE(SUM(jump_count), 0) FROM dropzone_users WHERE id IN (#{list})) WHERE id = #{keeper}"

    # Permissions are unique per member and permission
    execute "UPDATE user_permissions SET dropzone_user_id = #{keeper} WHERE dropzone_user_id IN (#{list}) AND permission_id NOT IN (SELECT permission_id FROM user_permissions WHERE dropzone_user_id = #{keeper})"
    execute "DELETE FROM user_permissions WHERE dropzone_user_id IN (#{list})"

    merge_slots(keeper, list)

    REFERENCES.each { |table, column| execute "UPDATE #{table} SET #{column} = #{keeper} WHERE #{column} IN (#{list})" }
    POLYMORPHIC.each do |table, name|
      execute "UPDATE #{table} SET #{name}_id = #{keeper} WHERE #{name}_type = 'DropzoneUser' AND #{name}_id IN (#{list})"
    end

    execute "DELETE FROM dropzone_users WHERE id IN (#{list})"
  end

  # A person has one slot per load: where several of the memberships have one on a load, the oldest one (the keeper's
  # first) stays and the others are dropped
  def merge_slots(keeper, list)
    conflicting = select_values(<<~SQL.squish).map(&:to_i)
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY load_id ORDER BY (dropzone_user_id = #{keeper}) DESC, created_at, id) AS position
        FROM slots
        WHERE dropzone_user_id IN (#{keeper},#{list})
      ) ranked
      WHERE position > 1
    SQL
    if conflicting.any?
      say "dropping #{conflicting.size} duplicate slot(s): #{conflicting.inspect}", true
      ids = conflicting.join(",")
      load_ids = select_values("SELECT DISTINCT load_id FROM slots WHERE id IN (#{ids})").map(&:to_i).join(",")
      execute "DELETE FROM slot_extras WHERE slot_id IN (#{ids})"
      execute "DELETE FROM slots WHERE id IN (#{ids})"
      execute "UPDATE loads SET slots_count = (SELECT COUNT(*) FROM slots WHERE slots.load_id = loads.id), ready_slots_count = (SELECT COUNT(*) FROM slots WHERE slots.load_id = loads.id AND (slots.dropzone_user_id IS NOT NULL OR slots.passenger_id IS NOT NULL)) WHERE id IN (#{load_ids})"
    end
    execute "UPDATE slots SET dropzone_user_id = #{keeper} WHERE dropzone_user_id IN (#{list})"
  end
end
