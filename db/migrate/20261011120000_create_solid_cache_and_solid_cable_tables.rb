# frozen_string_literal: true

# Solid Cache's and Solid Cable's tables in the primary database (the "single database" setup of their READMEs), taken from
# the schemas `bin/rails solid_cache:install` and `bin/rails solid_cable:install` generate. They replace Redis as the
# production cache and as the Action Cable adapter.
class CreateSolidCacheAndSolidCableTables < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.bigint :key_hash, null: false
      t.integer :byte_size, null: false
      t.index :byte_size, name: "index_solid_cache_entries_on_byte_size"
      t.index [:key_hash, :byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index :key_hash, unique: true, name: "index_solid_cache_entries_on_key_hash"
    end

    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.bigint :channel_hash, null: false
      t.index :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
      t.index :created_at, name: "index_solid_cable_messages_on_created_at"
    end
  end
end
