# frozen_string_literal: true

# Money as integer cents (BUG-048). Every money column gets a `*_cents` bigint beside it, backfilled from the old value
# (units * 100, rounded). The models read and write the cents and keep the old column current, so the old code and the old
# columns still work for a rollback; the old columns are dropped after the production data has been migrated (P8.8).
class AddCentsColumnsForMoney < ActiveRecord::Migration[8.1]
  # [table, old column, new column]
  COLUMNS = [
    [:dropzones, :credits, :credits_cents],
    [:dropzone_users, :credits, :credits_cents],
    [:ticket_types, :cost, :cost_cents],
    [:extras, :cost, :cost_cents],
    [:orders, :amount, :amount_cents],
    [:transactions, :amount, :amount_cents],
  ].freeze

  def up
    COLUMNS.each { |table, _old, new| add_column table, new, :bigint }
    backfill_cents
  end

  def backfill_cents
    COLUMNS.each do |table, old, new|
      execute "UPDATE #{table} SET #{new} = ROUND(#{old}::numeric * 100)::bigint WHERE #{old} IS NOT NULL"
    end
  end

  def down
    COLUMNS.reverse_each { |table, _old, new| remove_column table, new }
  end
end
