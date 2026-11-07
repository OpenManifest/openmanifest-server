# frozen_string_literal: true

# P7.13 (GENERALISATION §8): federations, licences and qualifications become certification bodies, levels (with a
# comparable rank) and qualifications; an operator accepts several bodies; ticket types ask for a minimum rank and
# ticket types and extras for a qualification. Reversible.
class GeneraliseCertifications < ActiveRecord::Migration[8.1]
  TABLES = {
    federations: :certification_bodies,
    licenses: :certification_levels,
    licensed_activity_types: :permitted_activities,
    user_federations: :user_certifications,
    user_federation_qualifications: :user_qualifications,
  }.freeze
  # [table (new name), old column, new column]
  COLUMNS = [
    [:certification_levels, :federation_id, :certification_body_id],
    [:permitted_activities, :license_id, :certification_level_id],
    [:qualifications, :federation_id, :certification_body_id],
    [:user_certifications, :federation_id, :certification_body_id],
    [:user_certifications, :license_id, :certification_level_id],
    [:user_certifications, :license_number, :number],
    [:user_qualifications, :user_federation_id, :user_certification_id],
    [:user_qualifications, :uid, :number],
    [:memberships, :license_id, :certification_level_id],
  ].freeze
  POLYMORPHIC = {
    active_storage_attachments: %i(record_type),
    events: %i(resource_type),
    notifications: %i(resource_type),
    orders: %i(seller_type buyer_type item_type),
    transactions: %i(sender_type receiver_type),
  }.freeze
  CLASSES = {
    "UserFederationQualification" => "UserQualification",
    "UserFederation" => "UserCertification",
    "LicensedActivityType" => "PermittedActivity",
    "Federation" => "CertificationBody",
    "License" => "CertificationLevel",
  }.freeze

  def up
    TABLES.each { |from, to| rename_table from, to }
    COLUMNS.each { |table, from, to| rename_column table, from, to }
    rename_classes(CLASSES)

    add_column :certification_bodies, :industry, :string
    add_column :certification_bodies, :verification_provider, :string
    execute "UPDATE certification_bodies SET industry = 'skydiving'"
    execute "UPDATE certification_bodies SET verification_provider = 'apf' WHERE slug = 'apf'"

    # Levels of a body are ranked in the order they were created (the lowest first), 10 apart; the catalogue sets the real ones
    add_column :certification_levels, :rank, :integer, null: false, default: 0
    add_column :certification_levels, :equivalence_key, :string
    execute <<~SQL.squish
      UPDATE certification_levels SET rank = ranked.position * 10
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY certification_body_id ORDER BY id) - 1 AS position FROM certification_levels
      ) AS ranked
      WHERE certification_levels.id = ranked.id
    SQL

    add_column :user_certifications, :verified_at, :datetime
    add_reference :user_certifications, :verified_by, foreign_key: { to_table: :users }
    add_column :user_qualifications, :verified_at, :datetime

    create_table :operator_certification_bodies do |t|
      t.references :operator, null: false, foreign_key: true
      t.references :certification_body, null: false, foreign_key: true
      t.timestamps
    end
    add_index :operator_certification_bodies, [:operator_id, :certification_body_id], unique: true,
                                                                                      name: "index_operator_certification_bodies_uniqueness"
    execute <<~SQL.squish
      INSERT INTO operator_certification_bodies (operator_id, certification_body_id, created_at, updated_at)
      SELECT id, federation_id, NOW(), NOW() FROM operators WHERE federation_id IS NOT NULL
    SQL
    remove_reference :operators, :federation, index: true

    # A licence kept on the user itself becomes a certification of the user in the body of the licence
    execute <<~SQL.squish
      INSERT INTO user_certifications (user_id, certification_body_id, certification_level_id, number, created_at, updated_at)
      SELECT users.id, certification_levels.certification_body_id, users.license_id, '', NOW(), NOW()
      FROM users JOIN certification_levels ON certification_levels.id = users.license_id
      WHERE NOT EXISTS (
        SELECT 1 FROM user_certifications
        WHERE user_certifications.user_id = users.id AND user_certifications.certification_body_id = certification_levels.certification_body_id
      )
    SQL
    remove_reference :users, :license, index: true, foreign_key: { to_table: :certification_levels }
    remove_column :users, :apf_number, :string

    # The setting that asks for a certification to manifest
    execute <<~SQL.squish
      UPDATE operators SET settings = (settings - 'require_license') || jsonb_build_object('require_certification', settings -> 'require_license')
      WHERE settings ? 'require_license'
    SQL

    add_column :ticket_types, :min_certification_rank, :integer
    add_reference :ticket_types, :required_qualification, foreign_key: { to_table: :qualifications }
    add_reference :extras, :required_qualification, foreign_key: { to_table: :qualifications }
  end

  def down
    execute <<~SQL.squish
      UPDATE operators SET settings = (settings - 'require_certification') || jsonb_build_object('require_license', settings -> 'require_certification')
      WHERE settings ? 'require_certification'
    SQL

    remove_reference :extras, :required_qualification, foreign_key: { to_table: :qualifications }
    remove_reference :ticket_types, :required_qualification, foreign_key: { to_table: :qualifications }
    remove_column :ticket_types, :min_certification_rank

    add_column :users, :apf_number, :string
    add_reference :users, :license, foreign_key: { to_table: :certification_levels }, index: true

    add_reference :operators, :federation, index: true
    execute <<~SQL.squish
      UPDATE operators SET federation_id = accepted.certification_body_id
      FROM (SELECT DISTINCT ON (operator_id) operator_id, certification_body_id FROM operator_certification_bodies ORDER BY operator_id, id) AS accepted
      WHERE operators.id = accepted.operator_id
    SQL
    drop_table :operator_certification_bodies

    remove_column :user_qualifications, :verified_at
    remove_reference :user_certifications, :verified_by, foreign_key: { to_table: :users }
    remove_column :user_certifications, :verified_at
    remove_column :certification_levels, :equivalence_key
    remove_column :certification_levels, :rank
    remove_column :certification_bodies, :verification_provider
    remove_column :certification_bodies, :industry

    rename_classes(CLASSES.invert)
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
