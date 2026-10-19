# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_13_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_types", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "participant_limits", default: {}, null: false
    t.index ["slug"], name: "index_activity_types_on_slug", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_admins_on_uid_and_provider", unique: true
  end

  create_table "authentication_providers", force: :cascade do |t|
    t.string "uid"
    t.integer "provider"
    t.bigint "user_id", null: false
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_authentication_providers_on_user_id"
  end

  create_table "certification_bodies", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "industry"
    t.string "verification_provider"
    t.index ["slug"], name: "index_certification_bodies_on_slug", unique: true
  end

  create_table "certification_levels", force: :cascade do |t|
    t.string "name"
    t.bigint "certification_body_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rank", default: 0, null: false
    t.string "equivalence_key"
    t.index ["certification_body_id"], name: "index_certification_levels_on_certification_body_id"
    t.index ["name", "certification_body_id"], name: "index_certification_levels_on_name_and_certification_body_id", unique: true
  end

  create_table "crew_roles", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "scope", default: "load", null: false
    t.boolean "required", default: false, null: false
    t.boolean "occupies_slot", default: false, null: false
    t.string "permission"
    t.jsonb "vehicle_kinds", default: [], null: false
    t.integer "position", default: 0, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_id", "key"], name: "index_crew_roles_on_operator_and_key", unique: true, where: "(discarded_at IS NULL)"
    t.index ["operator_id"], name: "index_crew_roles_on_operator_id"
  end

  create_table "daily_logs", force: :cascade do |t|
    t.bigint "duty_officer_id"
    t.bigint "operator_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.index ["duty_officer_id"], name: "index_daily_logs_on_duty_officer_id"
    t.index ["operator_id"], name: "index_daily_logs_on_operator_id"
  end

  create_table "destinations", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.string "kind", default: "altitude", null: false
    t.string "name", null: false
    t.decimal "altitude_m", precision: 10, scale: 2
    t.jsonb "location", default: {}, null: false
    t.jsonb "stops", default: [], null: false
    t.integer "min_certification_rank"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_destinations_on_discarded_at"
    t.index ["operator_id", "name"], name: "index_destinations_on_operator_and_name", unique: true, where: "(discarded_at IS NULL)"
    t.index ["operator_id"], name: "index_destinations_on_operator_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.string "serial"
    t.datetime "service_due_at", precision: nil
    t.datetime "maintained_at", precision: nil
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "operator_id"
    t.boolean "is_public", default: false
    t.string "name"
    t.text "packing_card"
    t.datetime "discarded_at", precision: nil
    t.bigint "kind_id"
    t.string "ownership", default: "personal", null: false
    t.jsonb "properties", default: {}, null: false
    t.index ["discarded_at"], name: "index_equipment_on_discarded_at"
    t.index ["kind_id"], name: "index_equipment_on_kind_id"
    t.index ["operator_id"], name: "index_equipment_on_operator_id"
    t.index ["user_id"], name: "index_equipment_on_user_id"
  end

  create_table "equipment_inspections", force: :cascade do |t|
    t.bigint "form_template_id", null: false
    t.bigint "membership_id", null: false
    t.bigint "equipment_id", null: false
    t.boolean "is_ok", default: false, null: false
    t.text "definition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "inspected_by_id"
    t.index ["equipment_id"], name: "index_equipment_inspections_on_equipment_id"
    t.index ["form_template_id"], name: "index_equipment_inspections_on_form_template_id"
    t.index ["inspected_by_id"], name: "index_equipment_inspections_on_inspected_by_id"
    t.index ["membership_id"], name: "index_equipment_inspections_on_membership_id"
  end

  create_table "equipment_kinds", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.jsonb "attribute_schema", default: {}, null: false
    t.integer "service_interval_days"
    t.bigint "inspection_form_template_id"
    t.integer "inspection_valid_days"
    t.jsonb "required_by", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.datetime "discarded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inspection_form_template_id"], name: "index_equipment_kinds_on_inspection_form_template_id"
    t.index ["operator_id", "key"], name: "index_equipment_kinds_on_operator_and_key", unique: true, where: "(discarded_at IS NULL)"
    t.index ["operator_id"], name: "index_equipment_kinds_on_operator_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.integer "action"
    t.integer "level"
    t.integer "access_level"
    t.bigint "membership_id"
    t.bigint "operator_id"
    t.text "message"
    t.text "details", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_level"], name: "index_events_on_access_level"
    t.index ["action"], name: "index_event_actions"
    t.index ["action"], name: "index_events_on_action"
    t.index ["level"], name: "index_events_on_level"
    t.index ["membership_id"], name: "index_events_on_membership_id"
    t.index ["operator_id", "created_at"], name: "index_events_on_operator_id_and_created_at"
    t.index ["operator_id"], name: "index_events_on_operator_id"
    t.index ["resource_type", "resource_id"], name: "index_events_on_resource"
  end

  create_table "extras", force: :cascade do |t|
    t.string "name"
    t.bigint "operator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.bigint "cost_cents"
    t.bigint "required_qualification_id"
    t.index ["discarded_at"], name: "index_extras_on_discarded_at"
    t.index ["operator_id"], name: "index_extras_on_operator_id"
    t.index ["required_qualification_id"], name: "index_extras_on_required_qualification_id"
  end

  create_table "form_templates", force: :cascade do |t|
    t.string "name"
    t.text "definition"
    t.bigint "operator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_form_templates_on_created_by_id"
    t.index ["operator_id"], name: "index_form_templates_on_operator_id"
    t.index ["updated_by_id"], name: "index_form_templates_on_updated_by_id"
  end

  create_table "guests", force: :cascade do |t|
    t.string "name"
    t.float "body_mass_kg"
    t.bigint "operator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "phone"
    t.date "date_of_birth"
    t.string "emergency_contact"
    t.index ["operator_id"], name: "index_guests_on_operator_id"
  end

  create_table "load_crew_assignments", force: :cascade do |t|
    t.bigint "load_id", null: false
    t.bigint "load_vehicle_id"
    t.bigint "crew_role_id", null: false
    t.bigint "membership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_role_id"], name: "index_load_crew_assignments_on_crew_role_id"
    t.index ["load_id", "crew_role_id"], name: "index_crew_assignments_per_load", unique: true, where: "(load_vehicle_id IS NULL)"
    t.index ["load_id", "load_vehicle_id", "crew_role_id"], name: "index_crew_assignments_per_vehicle", unique: true, where: "(load_vehicle_id IS NOT NULL)"
    t.index ["load_id"], name: "index_load_crew_assignments_on_load_id"
    t.index ["load_vehicle_id"], name: "index_load_crew_assignments_on_load_vehicle_id"
    t.index ["membership_id"], name: "index_load_crew_assignments_on_membership_id"
  end

  create_table "load_destinations", force: :cascade do |t|
    t.bigint "load_id", null: false
    t.bigint "destination_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_load_destinations_on_destination_id"
    t.index ["load_id", "position"], name: "index_load_destinations_on_load_and_position", unique: true
    t.index ["load_id"], name: "index_load_destinations_on_load_id"
  end

  create_table "load_vehicles", force: :cascade do |t|
    t.bigint "load_id", null: false
    t.bigint "vehicle_id", null: false
    t.string "role", default: "carrying", null: false
    t.integer "position", default: 0, null: false
    t.integer "slots_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["load_id", "position"], name: "index_load_vehicles_on_load_and_position"
    t.index ["load_id", "vehicle_id"], name: "index_load_vehicles_on_load_and_vehicle", unique: true
    t.index ["load_id"], name: "index_load_vehicles_on_load_id"
    t.index ["vehicle_id"], name: "index_load_vehicles_on_vehicle_id"
  end

  create_table "loads", force: :cascade do |t|
    t.datetime "dispatch_at", precision: nil
    t.boolean "has_completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "max_slots", default: 0
    t.boolean "is_open"
    t.integer "state"
    t.integer "load_number"
    t.datetime "discarded_at", precision: nil
    t.bigint "slots_count", default: 0
    t.bigint "ready_slots_count", default: 0
    t.bigint "operator_id", null: false
    t.date "load_date", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["discarded_at"], name: "index_loads_on_discarded_at"
    t.index ["operator_id", "load_date", "load_number"], name: "index_loads_on_operator_id_and_load_date_and_load_number", unique: true
    t.index ["ready_slots_count"], name: "index_loads_on_ready_slots_count"
    t.index ["slots_count"], name: "index_loads_on_slots_count"
    t.index ["state"], name: "index_loads_on_state"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "operator_id", null: false
    t.datetime "expires_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_role_id", null: false
    t.integer "load_count", default: 0, null: false
    t.datetime "discarded_at", precision: nil
    t.bigint "certification_level_id"
    t.bigint "credits_cents"
    t.index ["certification_level_id"], name: "index_memberships_on_certification_level_id"
    t.index ["discarded_at"], name: "index_memberships_on_discarded_at"
    t.index ["operator_id"], name: "index_memberships_on_operator_id"
    t.index ["user_id", "operator_id"], name: "index_memberships_on_user_id_and_operator_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.index ["user_role_id"], name: "index_memberships_on_user_role_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.bigint "received_by_id", null: false
    t.bigint "sent_by_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.integer "notification_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_seen", default: false
    t.index ["received_by_id", "is_seen"], name: "index_notifications_on_received_by_id_and_is_seen"
    t.index ["received_by_id"], name: "index_notifications_on_received_by_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["sent_by_id"], name: "index_notifications_on_sent_by_id"
  end

  create_table "operator_activity_types", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.bigint "activity_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type_id"], name: "index_operator_activity_types_on_activity_type_id"
    t.index ["operator_id", "activity_type_id"], name: "index_operator_activity_types_uniqueness", unique: true
    t.index ["operator_id"], name: "index_operator_activity_types_on_operator_id"
  end

  create_table "operator_certification_bodies", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.bigint "certification_body_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certification_body_id"], name: "index_operator_certification_bodies_on_certification_body_id"
    t.index ["operator_id", "certification_body_id"], name: "index_operator_certification_bodies_uniqueness", unique: true
    t.index ["operator_id"], name: "index_operator_certification_bodies_on_operator_id"
  end

  create_table "operators", force: :cascade do |t|
    t.string "name"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_public"
    t.string "primary_color"
    t.string "secondary_color"
    t.boolean "is_credit_system_enabled", default: false
    t.string "image"
    t.string "time_zone", null: false
    t.integer "users_count", default: 0, null: false
    t.integer "slots_count", default: 0, null: false
    t.integer "loads_count", default: 0, null: false
    t.boolean "request_publication", default: false
    t.datetime "discarded_at", precision: nil
    t.string "state", default: "private"
    t.jsonb "settings", default: {}
    t.bigint "credits_cents"
    t.string "industry", null: false
    t.jsonb "modules", default: {}, null: false
    t.string "currency", default: "AUD", null: false
    t.index ["discarded_at"], name: "index_operators_on_discarded_at"
    t.index ["state"], name: "index_operators_on_state"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.string "seller_type", null: false
    t.bigint "seller_id", null: false
    t.string "buyer_type", null: false
    t.bigint "buyer_id", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.integer "order_number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state"
    t.string "title"
    t.bigint "amount_cents"
    t.index ["buyer_type", "buyer_id"], name: "index_orders_on_buyer"
    t.index ["item_type", "item_id"], name: "index_orders_on_item"
    t.index ["operator_id", "order_number"], name: "index_orders_on_operator_id_and_order_number", unique: true
    t.index ["operator_id"], name: "index_orders_on_operator_id"
    t.index ["seller_type", "seller_id"], name: "index_orders_on_seller"
    t.index ["state"], name: "index_orders_on_state"
  end

  create_table "packs", force: :cascade do |t|
    t.bigint "equipment_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id"], name: "index_packs_on_equipment_id"
    t.index ["user_id"], name: "index_packs_on_user_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["name"], name: "index_permissions_on_name", unique: true
  end

  create_table "permitted_activities", force: :cascade do |t|
    t.bigint "certification_level_id", null: false
    t.bigint "activity_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type_id"], name: "index_permitted_activities_on_activity_type_id"
    t.index ["certification_level_id", "activity_type_id"], name: "idx_on_certification_level_id_activity_type_id_2973f01282", unique: true
    t.index ["certification_level_id"], name: "index_permitted_activities_on_certification_level_id"
  end

  create_table "qualifications", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "certification_body_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certification_body_id"], name: "index_qualifications_on_certification_body_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.index ["order_id"], name: "index_receipts_on_order_id"
  end

  create_table "slot_equipment", force: :cascade do |t|
    t.bigint "slot_id", null: false
    t.bigint "equipment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id"], name: "index_slot_equipment_on_equipment_id"
    t.index ["slot_id", "equipment_id"], name: "index_slot_equipment_on_slot_id_and_equipment_id", unique: true
    t.index ["slot_id"], name: "index_slot_equipment_on_slot_id"
  end

  create_table "slot_extras", force: :cascade do |t|
    t.bigint "slot_id", null: false
    t.bigint "extra_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extra_id"], name: "index_slot_extras_on_extra_id"
    t.index ["slot_id"], name: "index_slot_extras_on_slot_id"
  end

  create_table "slots", force: :cascade do |t|
    t.bigint "ticket_type_id"
    t.bigint "load_id"
    t.bigint "activity_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "body_mass_kg"
    t.bigint "guest_id"
    t.boolean "is_paid"
    t.bigint "transaction_id"
    t.integer "group_number", default: 0, null: false
    t.bigint "membership_id"
    t.bigint "created_by_id"
    t.integer "lock_version", default: 0, null: false
    t.bigint "destination_id"
    t.bigint "load_vehicle_id"
    t.bigint "escort_slot_id"
    t.index ["activity_type_id"], name: "index_slots_on_activity_type_id"
    t.index ["created_by_id"], name: "index_slots_on_created_by_id"
    t.index ["destination_id"], name: "index_slots_on_destination_id"
    t.index ["escort_slot_id"], name: "index_slots_on_escort_slot_id"
    t.index ["guest_id"], name: "index_slots_on_guest_id"
    t.index ["load_id", "membership_id"], name: "index_slots_on_load_id_and_membership_id", unique: true, where: "(membership_id IS NOT NULL)"
    t.index ["load_id"], name: "index_slots_on_load_id"
    t.index ["load_vehicle_id"], name: "index_slots_on_load_vehicle_id"
    t.index ["membership_id"], name: "index_slots_on_membership_id"
    t.index ["ticket_type_id"], name: "index_slots_on_ticket_type_id"
    t.index ["transaction_id"], name: "index_slots_on_transaction_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "ticket_type_extras", force: :cascade do |t|
    t.bigint "ticket_type_id", null: false
    t.bigint "extra_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extra_id"], name: "index_ticket_type_extras_on_extra_id"
    t.index ["ticket_type_id"], name: "index_ticket_type_extras_on_ticket_type_id"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.string "currency"
    t.string "name"
    t.bigint "operator_id", null: false
    t.boolean "allow_manifesting_self"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "requires_escort", default: false
    t.datetime "discarded_at", precision: nil
    t.bigint "cost_cents"
    t.bigint "default_destination_id"
    t.integer "min_certification_rank"
    t.bigint "required_qualification_id"
    t.integer "escort_capacity", default: 1, null: false
    t.bigint "escort_qualification_id"
    t.bigint "escort_crew_role_id"
    t.jsonb "participant_limits", default: {}, null: false
    t.jsonb "group_limits", default: {}, null: false
    t.index ["default_destination_id"], name: "index_ticket_types_on_default_destination_id"
    t.index ["discarded_at"], name: "index_ticket_types_on_discarded_at"
    t.index ["escort_crew_role_id"], name: "index_ticket_types_on_escort_crew_role_id"
    t.index ["escort_qualification_id"], name: "index_ticket_types_on_escort_qualification_id"
    t.index ["operator_id"], name: "index_ticket_types_on_operator_id"
    t.index ["required_qualification_id"], name: "index_ticket_types_on_required_qualification_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message"
    t.string "sender_type", null: false
    t.bigint "sender_id", null: false
    t.string "receiver_type", null: false
    t.bigint "receiver_id", null: false
    t.bigint "receipt_id", null: false
    t.integer "transaction_type"
    t.bigint "amount_cents"
    t.index ["receipt_id"], name: "index_transactions_on_receipt_id"
    t.index ["receiver_type", "receiver_id"], name: "index_transactions_on_receiver"
    t.index ["sender_type", "sender_id"], name: "index_transactions_on_sender"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "user_certifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "certification_body_id", null: false
    t.bigint "certification_level_id"
    t.string "uid"
    t.string "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.bigint "verified_by_id"
    t.index ["certification_body_id"], name: "index_user_certifications_on_certification_body_id"
    t.index ["certification_level_id"], name: "index_user_certifications_on_certification_level_id"
    t.index ["user_id"], name: "index_user_certifications_on_user_id"
    t.index ["verified_by_id"], name: "index_user_certifications_on_verified_by_id"
  end

  create_table "user_permissions", force: :cascade do |t|
    t.bigint "permission_id", null: false
    t.bigint "membership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["membership_id", "permission_id"], name: "index_user_permissions_on_membership_id_and_permission_id", unique: true
    t.index ["membership_id"], name: "index_user_permissions_on_membership_id"
    t.index ["permission_id"], name: "index_user_permissions_on_permission_id"
  end

  create_table "user_qualifications", force: :cascade do |t|
    t.bigint "user_certification_id", null: false
    t.bigint "qualification_id", null: false
    t.datetime "expires_at", precision: nil
    t.string "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["qualification_id"], name: "index_user_qualifications_on_qualification_id"
    t.index ["user_certification_id"], name: "index_user_qualifications_on_user_certification_id"
  end

  create_table "user_role_permissions", force: :cascade do |t|
    t.bigint "permission_id", null: false
    t.bigint "user_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_user_role_permissions_on_permission_id"
    t.index ["user_role_id", "permission_id"], name: "index_user_role_permissions_on_user_role_id_and_permission_id", unique: true
    t.index ["user_role_id"], name: "index_user_role_permissions_on_user_role_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "operator_id", null: false
    t.boolean "is_default", default: false, null: false
    t.boolean "is_default_certified", default: false, null: false
    t.index ["name", "operator_id"], name: "index_user_roles_on_name_and_operator_id", unique: true
    t.index ["operator_id"], name: "index_user_roles_on_operator_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "phone"
    t.string "email"
    t.float "body_mass_kg"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "push_token"
    t.string "unconfirmed_email"
    t.string "time_zone", default: "Australia/Brisbane"
    t.integer "load_count", default: 0, null: false
    t.integer "operator_count", default: 0, null: false
    t.integer "moderation_role", default: 0
    t.date "date_of_birth"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name"
    t.integer "min_capacity"
    t.integer "capacity"
    t.integer "hours"
    t.integer "next_maintenance_hours"
    t.string "registration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "operator_id", null: false
    t.datetime "discarded_at", precision: nil
    t.string "kind", null: false
    t.decimal "max_payload_kg", precision: 8, scale: 2
    t.index ["discarded_at"], name: "index_vehicles_on_discarded_at"
    t.index ["operator_id"], name: "index_vehicles_on_operator_id"
  end

  create_table "weather_conditions", force: :cascade do |t|
    t.text "winds"
    t.decimal "temperature_c", precision: 5, scale: 1
    t.integer "jump_run"
    t.decimal "exit_spot_m", precision: 10, scale: 2
    t.decimal "offset_m", precision: 10, scale: 2
    t.integer "offset_direction"
    t.bigint "operator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", null: false
    t.index ["operator_id", "date"], name: "index_weather_conditions_on_operator_id_and_date", unique: true
    t.index ["operator_id"], name: "index_weather_conditions_on_operator_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authentication_providers", "users"
  add_foreign_key "certification_levels", "certification_bodies"
  add_foreign_key "crew_roles", "operators"
  add_foreign_key "daily_logs", "memberships", column: "duty_officer_id"
  add_foreign_key "daily_logs", "operators"
  add_foreign_key "destinations", "operators"
  add_foreign_key "equipment", "equipment_kinds", column: "kind_id"
  add_foreign_key "equipment", "operators"
  add_foreign_key "equipment", "users"
  add_foreign_key "equipment_inspections", "equipment"
  add_foreign_key "equipment_inspections", "form_templates"
  add_foreign_key "equipment_inspections", "memberships"
  add_foreign_key "equipment_inspections", "memberships", column: "inspected_by_id"
  add_foreign_key "equipment_kinds", "form_templates", column: "inspection_form_template_id"
  add_foreign_key "equipment_kinds", "operators"
  add_foreign_key "events", "memberships"
  add_foreign_key "events", "operators"
  add_foreign_key "extras", "operators"
  add_foreign_key "extras", "qualifications", column: "required_qualification_id"
  add_foreign_key "form_templates", "memberships", column: "created_by_id"
  add_foreign_key "form_templates", "memberships", column: "updated_by_id"
  add_foreign_key "form_templates", "operators"
  add_foreign_key "guests", "operators"
  add_foreign_key "load_crew_assignments", "crew_roles"
  add_foreign_key "load_crew_assignments", "load_vehicles"
  add_foreign_key "load_crew_assignments", "loads"
  add_foreign_key "load_crew_assignments", "memberships"
  add_foreign_key "load_destinations", "destinations"
  add_foreign_key "load_destinations", "loads"
  add_foreign_key "load_vehicles", "loads"
  add_foreign_key "load_vehicles", "vehicles"
  add_foreign_key "loads", "operators"
  add_foreign_key "memberships", "certification_levels"
  add_foreign_key "memberships", "operators"
  add_foreign_key "memberships", "user_roles"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "memberships", column: "received_by_id"
  add_foreign_key "notifications", "memberships", column: "sent_by_id"
  add_foreign_key "operator_activity_types", "activity_types"
  add_foreign_key "operator_activity_types", "operators"
  add_foreign_key "operator_certification_bodies", "certification_bodies"
  add_foreign_key "operator_certification_bodies", "operators"
  add_foreign_key "orders", "operators"
  add_foreign_key "packs", "equipment"
  add_foreign_key "packs", "users"
  add_foreign_key "permitted_activities", "activity_types"
  add_foreign_key "permitted_activities", "certification_levels"
  add_foreign_key "qualifications", "certification_bodies"
  add_foreign_key "slot_equipment", "equipment"
  add_foreign_key "slot_equipment", "slots"
  add_foreign_key "slot_extras", "extras"
  add_foreign_key "slot_extras", "slots"
  add_foreign_key "slots", "activity_types"
  add_foreign_key "slots", "destinations"
  add_foreign_key "slots", "guests"
  add_foreign_key "slots", "load_vehicles"
  add_foreign_key "slots", "loads"
  add_foreign_key "slots", "memberships"
  add_foreign_key "slots", "memberships", column: "created_by_id"
  add_foreign_key "slots", "slots", column: "escort_slot_id"
  add_foreign_key "slots", "ticket_types"
  add_foreign_key "slots", "transactions"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "ticket_type_extras", "extras"
  add_foreign_key "ticket_type_extras", "ticket_types"
  add_foreign_key "ticket_types", "crew_roles", column: "escort_crew_role_id"
  add_foreign_key "ticket_types", "destinations", column: "default_destination_id"
  add_foreign_key "ticket_types", "operators"
  add_foreign_key "ticket_types", "qualifications", column: "escort_qualification_id"
  add_foreign_key "ticket_types", "qualifications", column: "required_qualification_id"
  add_foreign_key "transactions", "receipts"
  add_foreign_key "user_certifications", "certification_bodies"
  add_foreign_key "user_certifications", "certification_levels"
  add_foreign_key "user_certifications", "users"
  add_foreign_key "user_certifications", "users", column: "verified_by_id"
  add_foreign_key "user_permissions", "memberships"
  add_foreign_key "user_permissions", "permissions"
  add_foreign_key "user_qualifications", "qualifications"
  add_foreign_key "user_qualifications", "user_certifications"
  add_foreign_key "user_role_permissions", "permissions"
  add_foreign_key "user_role_permissions", "user_roles"
  add_foreign_key "user_roles", "operators"
  add_foreign_key "vehicles", "operators"
  add_foreign_key "weather_conditions", "operators"
end
