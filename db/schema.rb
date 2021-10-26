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

ActiveRecord::Schema.define(version: 2021_10_24_100955) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
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
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_admins_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_admins_on_uid_and_provider", unique: true
  end

  create_table "dropzone_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "dropzone_id", null: false
    t.float "credits"
    t.datetime "expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_role_id", null: false
    t.integer "jump_count", default: 0, null: false
    t.index ["dropzone_id"], name: "index_dropzone_users_on_dropzone_id"
    t.index ["user_id"], name: "index_dropzone_users_on_user_id"
    t.index ["user_role_id"], name: "index_dropzone_users_on_user_role_id"
  end

  create_table "dropzones", force: :cascade do |t|
    t.string "name"
    t.bigint "federation_id"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_public"
    t.string "primary_color"
    t.string "secondary_color"
    t.boolean "is_credit_system_enabled", default: false
    t.bigint "rig_inspection_template_id"
    t.string "image"
    t.string "time_zone", default: "Australia/Brisbane"
    t.integer "users_count", default: 0, null: false
    t.integer "slots_count", default: 0, null: false
    t.integer "loads_count", default: 0, null: false
    t.integer "credits"
    t.index ["federation_id"], name: "index_dropzones_on_federation_id"
    t.index ["rig_inspection_template_id"], name: "index_dropzones_on_rig_inspection_template_id"
  end

  create_table "extras", force: :cascade do |t|
    t.float "cost"
    t.string "name"
    t.bigint "dropzone_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_deleted", default: false
    t.index ["dropzone_id"], name: "index_extras_on_dropzone_id"
  end

  create_table "federations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "form_templates", force: :cascade do |t|
    t.string "name"
    t.text "definition"
    t.bigint "dropzone_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_form_templates_on_created_by_id"
    t.index ["dropzone_id"], name: "index_form_templates_on_dropzone_id"
    t.index ["updated_by_id"], name: "index_form_templates_on_updated_by_id"
  end

  create_table "jump_types", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "licensed_jump_types", force: :cascade do |t|
    t.bigint "license_id", null: false
    t.bigint "jump_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jump_type_id"], name: "index_licensed_jump_types_on_jump_type_id"
    t.index ["license_id"], name: "index_licensed_jump_types_on_license_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.string "name"
    t.bigint "federation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["federation_id"], name: "index_licenses_on_federation_id"
  end

  create_table "loads", force: :cascade do |t|
    t.datetime "dispatch_at"
    t.boolean "has_landed"
    t.bigint "plane_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.integer "max_slots", default: 0
    t.boolean "is_open"
    t.bigint "gca_id"
    t.bigint "load_master_id"
    t.bigint "pilot_id"
    t.integer "state"
    t.integer "load_number"
    t.index ["gca_id"], name: "index_loads_on_gca_id"
    t.index ["load_master_id"], name: "index_loads_on_load_master_id"
    t.index ["pilot_id"], name: "index_loads_on_pilot_id"
    t.index ["plane_id"], name: "index_loads_on_plane_id"
  end

  create_table "master_logs", force: :cascade do |t|
    t.bigint "dzso_id"
    t.bigint "dropzone_id", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_id"], name: "index_master_logs_on_dropzone_id"
    t.index ["dzso_id"], name: "index_master_logs_on_dzso_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.bigint "received_by_id", null: false
    t.bigint "sent_by_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.integer "notification_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_seen", default: false
    t.index ["received_by_id"], name: "index_notifications_on_received_by_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["sent_by_id"], name: "index_notifications_on_sent_by_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "dropzone_id", null: false
    t.string "seller_type", null: false
    t.bigint "seller_id", null: false
    t.string "buyer_type", null: false
    t.bigint "buyer_id", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.integer "order_number", default: 1, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "state"
    t.float "amount"
    t.string "title"
    t.index ["buyer_type", "buyer_id"], name: "index_orders_on_buyer"
    t.index ["dropzone_id"], name: "index_orders_on_dropzone_id"
    t.index ["item_type", "item_id"], name: "index_orders_on_item"
    t.index ["seller_type", "seller_id"], name: "index_orders_on_seller"
  end

  create_table "packs", force: :cascade do |t|
    t.bigint "rig_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rig_id"], name: "index_packs_on_rig_id"
    t.index ["user_id"], name: "index_packs_on_user_id"
  end

  create_table "passengers", force: :cascade do |t|
    t.string "name"
    t.float "exit_weight"
    t.bigint "dropzone_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_id"], name: "index_passengers_on_dropzone_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
  end

  create_table "planes", force: :cascade do |t|
    t.string "name"
    t.integer "min_slots"
    t.integer "max_slots"
    t.integer "hours"
    t.integer "next_maintenance_hours"
    t.string "registration"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "dropzone_id", null: false
    t.boolean "is_deleted", default: false
    t.index ["dropzone_id"], name: "index_planes_on_dropzone_id"
  end

  create_table "qualifications", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "federation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["federation_id"], name: "index_qualifications_on_federation_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "amount_cents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "order_id"
    t.index ["order_id"], name: "index_receipts_on_order_id"
  end

  create_table "rig_inspections", force: :cascade do |t|
    t.bigint "form_template_id", null: false
    t.bigint "dropzone_user_id", null: false
    t.bigint "rig_id", null: false
    t.boolean "is_ok", default: false, null: false
    t.text "definition"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "inspected_by_id"
    t.index ["dropzone_user_id"], name: "index_rig_inspections_on_dropzone_user_id"
    t.index ["form_template_id"], name: "index_rig_inspections_on_form_template_id"
    t.index ["inspected_by_id"], name: "index_rig_inspections_on_inspected_by_id"
    t.index ["rig_id"], name: "index_rig_inspections_on_rig_id"
  end

  create_table "rigs", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.string "serial"
    t.integer "pack_value"
    t.datetime "repack_expires_at"
    t.datetime "maintained_at"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "dropzone_id"
    t.integer "canopy_size"
    t.boolean "is_public", default: false
    t.integer "rig_type"
    t.string "name"
    t.text "packing_card"
    t.index ["dropzone_id"], name: "index_rigs_on_dropzone_id"
    t.index ["user_id"], name: "index_rigs_on_user_id"
  end

  create_table "slot_extras", force: :cascade do |t|
    t.bigint "slot_id", null: false
    t.bigint "extra_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["extra_id"], name: "index_slot_extras_on_extra_id"
    t.index ["slot_id"], name: "index_slot_extras_on_slot_id"
  end

  create_table "slots", force: :cascade do |t|
    t.bigint "ticket_type_id"
    t.bigint "load_id"
    t.bigint "rig_id"
    t.bigint "jump_type_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "exit_weight"
    t.bigint "passenger_id"
    t.boolean "is_paid"
    t.bigint "transaction_id"
    t.bigint "passenger_slot_id"
    t.integer "group_number", default: 0, null: false
    t.bigint "dropzone_user_id"
    t.index ["dropzone_user_id"], name: "index_slots_on_dropzone_user_id"
    t.index ["jump_type_id"], name: "index_slots_on_jump_type_id"
    t.index ["load_id"], name: "index_slots_on_load_id"
    t.index ["passenger_id"], name: "index_slots_on_passenger_id"
    t.index ["passenger_slot_id"], name: "index_slots_on_passenger_slot_id"
    t.index ["rig_id"], name: "index_slots_on_rig_id"
    t.index ["ticket_type_id"], name: "index_slots_on_ticket_type_id"
    t.index ["transaction_id"], name: "index_slots_on_transaction_id"
  end

  create_table "ticket_type_extras", force: :cascade do |t|
    t.bigint "ticket_type_id", null: false
    t.bigint "extra_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["extra_id"], name: "index_ticket_type_extras_on_extra_id"
    t.index ["ticket_type_id"], name: "index_ticket_type_extras_on_ticket_type_id"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.float "cost"
    t.string "currency"
    t.string "name"
    t.bigint "dropzone_id", null: false
    t.integer "altitude"
    t.boolean "allow_manifesting_self"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_tandem", default: false
    t.boolean "is_deleted", default: false
    t.index ["dropzone_id"], name: "index_ticket_types_on_dropzone_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "status"
    t.float "amount"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "message"
    t.string "sender_type", null: false
    t.bigint "sender_id", null: false
    t.string "receiver_type", null: false
    t.bigint "receiver_id", null: false
    t.bigint "receipt_id", null: false
    t.integer "transaction_type"
    t.index ["receipt_id"], name: "index_transactions_on_receipt_id"
    t.index ["receiver_type", "receiver_id"], name: "index_transactions_on_receiver"
    t.index ["sender_type", "sender_id"], name: "index_transactions_on_sender"
    t.index ["status"], name: "index_transactions_on_status"
  end

  create_table "user_federation_qualifications", force: :cascade do |t|
    t.bigint "user_federation_id", null: false
    t.bigint "qualification_id", null: false
    t.datetime "expires_at"
    t.string "uid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["qualification_id"], name: "index_user_federation_qualifications_on_qualification_id"
    t.index ["user_federation_id"], name: "index_user_federation_qualifications_on_user_federation_id"
  end

  create_table "user_federations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "federation_id", null: false
    t.bigint "license_id"
    t.string "uid"
    t.string "license_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["federation_id"], name: "index_user_federations_on_federation_id"
    t.index ["license_id"], name: "index_user_federations_on_license_id"
    t.index ["user_id"], name: "index_user_federations_on_user_id"
  end

  create_table "user_permissions", force: :cascade do |t|
    t.bigint "permission_id", null: false
    t.bigint "dropzone_user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_user_id"], name: "index_user_permissions_on_dropzone_user_id"
    t.index ["permission_id"], name: "index_user_permissions_on_permission_id"
  end

  create_table "user_role_permissions", force: :cascade do |t|
    t.bigint "permission_id", null: false
    t.bigint "user_role_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["permission_id"], name: "index_user_role_permissions_on_permission_id"
    t.index ["user_role_id"], name: "index_user_role_permissions_on_user_role_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "dropzone_id", null: false
    t.index ["dropzone_id"], name: "index_user_roles_on_dropzone_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "phone"
    t.string "email"
    t.float "exit_weight"
    t.bigint "license_id"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "push_token"
    t.string "unconfirmed_email"
    t.string "time_zone", default: "Australia/Brisbane"
    t.integer "jump_count", default: 0, null: false
    t.integer "dropzone_count", default: 0, null: false
    t.integer "plane_count", default: 0, null: false
    t.string "apf_number"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["license_id"], name: "index_users_on_license_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "weather_conditions", force: :cascade do |t|
    t.text "winds"
    t.integer "temperature"
    t.integer "jump_run"
    t.integer "exit_spot_miles"
    t.integer "offset_miles"
    t.integer "offset_direction"
    t.bigint "dropzone_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_id"], name: "index_weather_conditions_on_dropzone_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dropzone_users", "dropzones"
  add_foreign_key "dropzone_users", "user_roles"
  add_foreign_key "dropzone_users", "users"
  add_foreign_key "dropzones", "form_templates", column: "rig_inspection_template_id"
  add_foreign_key "extras", "dropzones"
  add_foreign_key "form_templates", "dropzone_users", column: "created_by_id"
  add_foreign_key "form_templates", "dropzone_users", column: "updated_by_id"
  add_foreign_key "form_templates", "dropzones"
  add_foreign_key "licensed_jump_types", "jump_types"
  add_foreign_key "licensed_jump_types", "licenses"
  add_foreign_key "licenses", "federations"
  add_foreign_key "loads", "dropzone_users", column: "gca_id"
  add_foreign_key "loads", "dropzone_users", column: "load_master_id"
  add_foreign_key "loads", "dropzone_users", column: "pilot_id"
  add_foreign_key "loads", "planes"
  add_foreign_key "master_logs", "dropzone_users", column: "dzso_id"
  add_foreign_key "master_logs", "dropzones"
  add_foreign_key "notifications", "dropzone_users", column: "received_by_id"
  add_foreign_key "notifications", "dropzone_users", column: "sent_by_id"
  add_foreign_key "orders", "dropzones"
  add_foreign_key "packs", "rigs"
  add_foreign_key "packs", "users"
  add_foreign_key "passengers", "dropzones"
  add_foreign_key "planes", "dropzones"
  add_foreign_key "qualifications", "federations"
  add_foreign_key "rig_inspections", "dropzone_users"
  add_foreign_key "rig_inspections", "dropzone_users", column: "inspected_by_id"
  add_foreign_key "rig_inspections", "form_templates"
  add_foreign_key "rig_inspections", "rigs"
  add_foreign_key "rigs", "dropzones"
  add_foreign_key "rigs", "users"
  add_foreign_key "slot_extras", "extras"
  add_foreign_key "slot_extras", "slots"
  add_foreign_key "slots", "dropzone_users"
  add_foreign_key "slots", "jump_types"
  add_foreign_key "slots", "loads"
  add_foreign_key "slots", "passengers"
  add_foreign_key "slots", "rigs"
  add_foreign_key "slots", "slots", column: "passenger_slot_id"
  add_foreign_key "slots", "ticket_types"
  add_foreign_key "slots", "transactions"
  add_foreign_key "ticket_type_extras", "extras"
  add_foreign_key "ticket_type_extras", "ticket_types"
  add_foreign_key "ticket_types", "dropzones"
  add_foreign_key "transactions", "receipts"
  add_foreign_key "user_federation_qualifications", "qualifications"
  add_foreign_key "user_federation_qualifications", "user_federations"
  add_foreign_key "user_federations", "federations"
  add_foreign_key "user_federations", "licenses"
  add_foreign_key "user_federations", "users"
  add_foreign_key "user_permissions", "dropzone_users"
  add_foreign_key "user_permissions", "permissions"
  add_foreign_key "user_role_permissions", "permissions"
  add_foreign_key "user_role_permissions", "user_roles"
  add_foreign_key "user_roles", "dropzones"
  add_foreign_key "users", "licenses"
  add_foreign_key "weather_conditions", "dropzones"
end
