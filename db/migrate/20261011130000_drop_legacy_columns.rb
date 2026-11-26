# frozen_string_literal: true

# P7.2 (D7: there is no production data to carry forward): the float money columns that P6.23 kept current beside the
# `*_cents` columns, and `is_deleted`, which `discarded_at` replaced.
class DropLegacyColumns < ActiveRecord::Migration[8.1]
  MONEY = [
    [:dropzones, :credits, :integer],
    [:dropzone_users, :credits, :float],
    [:ticket_types, :cost, :float],
    [:extras, :cost, :float],
    [:orders, :amount, :float],
    [:transactions, :amount, :float],
  ].freeze
  DELETED = [:planes, :ticket_types, :extras].freeze

  def change
    MONEY.each { |table, column, type| remove_column table, column, type }
    DELETED.each { |table| remove_column table, :is_deleted, :boolean, default: false }
  end
end
