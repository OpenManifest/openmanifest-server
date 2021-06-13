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

ActiveRecord::Schema.define(version: 2021_06_13_044719) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
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
    t.integer "blob_id", null: false
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
    t.integer "user_id", null: false
    t.integer "dropzone_id", null: false
    t.float "credits"
    t.datetime "expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_role_id", null: false
    t.index ["dropzone_id"], name: "index_dropzone_users_on_dropzone_id"
    t.index ["user_id"], name: "index_dropzone_users_on_user_id"
    t.index ["user_role_id"], name: "index_dropzone_users_on_user_role_id"
  end

  create_table "dropzones", force: :cascade do |t|
    t.string "name"
    t.integer "federation_id"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_public"
    t.string "primary_color"
    t.string "secondary_color"
    t.boolean "is_credit_system_enabled", default: false
    t.integer "rig_inspection_template_id"
    t.string "image"
    t.index ["federation_id"], name: "index_dropzones_on_federation_id"
    t.index ["rig_inspection_template_id"], name: "index_dropzones_on_rig_inspection_template_id"
  end

  create_table "extras", force: :cascade do |t|
    t.float "cost"
    t.string "name"
    t.integer "dropzone_id", null: false
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
    t.integer "dropzone_id"
    t.integer "created_by_id", null: false
    t.integer "updated_by_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.integer "license_id", null: false
    t.integer "jump_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["jump_type_id"], name: "index_licensed_jump_types_on_jump_type_id"
    t.index ["license_id"], name: "index_licensed_jump_types_on_license_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.string "name"
    t.integer "federation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["federation_id"], name: "index_licenses_on_federation_id"
  end

  create_table "loads", force: :cascade do |t|
    t.datetime "dispatch_at"
    t.boolean "has_landed"
    t.integer "plane_id", null: false
    t.integer "load_master_id"
    t.integer "gca_id"
    t.integer "pilot_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.integer "max_slots", default: 0
    t.boolean "is_open"
    t.index ["gca_id"], name: "index_loads_on_gca_id"
    t.index ["load_master_id"], name: "index_loads_on_load_master_id"
    t.index ["pilot_id"], name: "index_loads_on_pilot_id"
    t.index ["plane_id"], name: "index_loads_on_plane_id"
  end

  create_table "master_logs", force: :cascade do |t|
    t.integer "dzso_id"
    t.integer "dropzone_id", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_id"], name: "index_master_logs_on_dropzone_id"
    t.index ["dzso_id"], name: "index_master_logs_on_dzso_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.integer "received_by_id", null: false
    t.integer "sent_by_id"
    t.string "resource_type"
    t.integer "resource_id"
    t.integer "notification_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_seen", default: false
    t.index ["received_by_id"], name: "index_notifications_on_received_by_id"
    t.index ["resource_type", "resource_id"], name: "index_notifications_on_resource"
    t.index ["sent_by_id"], name: "index_notifications_on_sent_by_id"
  end

  create_table "packs", force: :cascade do |t|
    t.integer "rig_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["rig_id"], name: "index_packs_on_rig_id"
    t.index ["user_id"], name: "index_packs_on_user_id"
  end

  create_table "passengers", force: :cascade do |t|
    t.string "name"
    t.float "exit_weight"
    t.integer "dropzone_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dropzone_id"], name: "index_passengers_on_dropzone_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.integer "name"
    t.integer "user_role_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_role_id"], name: "index_permissions_on_user_role_id"
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
    t.integer "dropzone_id", null: false
    t.boolean "is_deleted", default: false
    t.index ["dropzone_id"], name: "index_planes_on_dropzone_id"
  end

  create_table "rig_inspections", force: :cascade do |t|
    t.integer "form_template_id", null: false
    t.integer "inspected_by_id", null: false
    t.integer "dropzone_user_id", null: false
    t.integer "rig_id", null: false
    t.boolean "is_ok", default: false, null: false
    t.text "definition"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "dropzone_id"
    t.integer "canopy_size"
    t.boolean "is_public", default: false
    t.integer "rig_type"
    t.index ["dropzone_id"], name: "index_rigs_on_dropzone_id"
    t.index ["user_id"], name: "index_rigs_on_user_id"
  end

  create_table "slot_extras", force: :cascade do |t|
    t.integer "slot_id", null: false
    t.integer "extra_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["extra_id"], name: "index_slot_extras_on_extra_id"
    t.index ["slot_id"], name: "index_slot_extras_on_slot_id"
  end

  create_table "slots", force: :cascade do |t|
    t.integer "user_id"
    t.integer "ticket_type_id"
    t.integer "load_id"
    t.integer "rig_id"
    t.integer "jump_type_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "exit_weight"
    t.integer "passenger_id"
    t.boolean "is_paid"
    t.integer "transaction_id"
    t.integer "passenger_slot_id"
    t.integer "group_number", default: 0, null: false
    t.index ["jump_type_id"], name: "index_slots_on_jump_type_id"
    t.index ["load_id"], name: "index_slots_on_load_id"
    t.index ["passenger_id"], name: "index_slots_on_passenger_id"
    t.index ["passenger_slot_id"], name: "index_slots_on_passenger_slot_id"
    t.index ["rig_id"], name: "index_slots_on_rig_id"
    t.index ["ticket_type_id"], name: "index_slots_on_ticket_type_id"
    t.index ["transaction_id"], name: "index_slots_on_transaction_id"
    t.index ["user_id"], name: "index_slots_on_user_id"
  end

  create_table "ticket_type_extras", force: :cascade do |t|
    t.integer "ticket_type_id", null: false
    t.integer "extra_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["extra_id"], name: "index_ticket_type_extras_on_extra_id"
    t.index ["ticket_type_id"], name: "index_ticket_type_extras_on_ticket_type_id"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.float "cost"
    t.string "currency"
    t.string "name"
    t.integer "dropzone_id", null: false
    t.integer "altitude"
    t.boolean "allow_manifesting_self"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_tandem", default: false
    t.boolean "is_deleted", default: false
    t.index ["dropzone_id"], name: "index_ticket_types_on_dropzone_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "dropzone_user_id", null: false
    t.integer "slot_id"
    t.integer "status"
    t.float "amount"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "message"
    t.index ["dropzone_user_id"], name: "index_transactions_on_dropzone_user_id"
    t.index ["slot_id"], name: "index_transactions_on_slot_id"
    t.index ["status"], name: "index_transactions_on_status"
  end

  create_table "user_roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "dropzone_id", null: false
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
    t.integer "license_id"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["license_id"], name: "index_users_on_license_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dropzone_users", "dropzones"
  add_foreign_key "dropzone_users", "user_roles"
  add_foreign_key "dropzone_users", "users"
  add_foreign_key "dropzones", "form_templates", column: "rig_inspection_template_id"
  add_foreign_key "extras", "dropzones"
  add_foreign_key "form_templates", "dropzones"
  add_foreign_key "form_templates", "users", column: "created_by_id"
  add_foreign_key "form_templates", "users", column: "updated_by_id"
  add_foreign_key "licensed_jump_types", "jump_types"
  add_foreign_key "licensed_jump_types", "licenses"
  add_foreign_key "licenses", "federations"
  add_foreign_key "loads", "planes"
  add_foreign_key "loads", "users", column: "gca_id"
  add_foreign_key "loads", "users", column: "load_master_id"
  add_foreign_key "loads", "users", column: "pilot_id"
  add_foreign_key "master_logs", "dropzone_users", column: "dzso_id"
  add_foreign_key "master_logs", "dropzones"
  add_foreign_key "notifications", "dropzone_users", column: "received_by_id"
  add_foreign_key "notifications", "dropzone_users", column: "sent_by_id"
  add_foreign_key "packs", "rigs"
  add_foreign_key "packs", "users"
  add_foreign_key "passengers", "dropzones"
  add_foreign_key "permissions", "user_roles"
  add_foreign_key "planes", "dropzones"
  add_foreign_key "rig_inspections", "dropzone_users"
  add_foreign_key "rig_inspections", "form_templates"
  add_foreign_key "rig_inspections", "rigs"
  add_foreign_key "rig_inspections", "users", column: "inspected_by_id"
  add_foreign_key "rigs", "dropzones"
  add_foreign_key "rigs", "users"
  add_foreign_key "slot_extras", "extras"
  add_foreign_key "slot_extras", "slots"
  add_foreign_key "slots", "jump_types"
  add_foreign_key "slots", "loads"
  add_foreign_key "slots", "passengers"
  add_foreign_key "slots", "rigs"
  add_foreign_key "slots", "slots", column: "passenger_slot_id"
  add_foreign_key "slots", "ticket_types"
  add_foreign_key "slots", "transactions"
  add_foreign_key "slots", "users"
  add_foreign_key "ticket_type_extras", "extras"
  add_foreign_key "ticket_type_extras", "ticket_types"
  add_foreign_key "ticket_types", "dropzones"
  add_foreign_key "transactions", "dropzone_users"
  add_foreign_key "transactions", "slots"
  add_foreign_key "user_roles", "dropzones"
  add_foreign_key "users", "licenses"
end
