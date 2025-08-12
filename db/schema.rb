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

ActiveRecord::Schema[8.0].define(version: 2025_08_12_130810) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "token", null: false
    t.string "role", default: "member", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.uuid "invited_by_id", null: false
    t.uuid "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "organization_id"], name: "index_invitations_on_email_and_organization_id", unique: true, where: "(accepted_at IS NULL)"
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "organization_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_users_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_users_on_organization_id"
    t.index ["role"], name: "index_organization_users_on_role"
    t.index ["user_id"], name: "index_organization_users_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name"
  end

  create_table "test_cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "priority", default: "medium", null: false
    t.text "description"
    t.jsonb "steps", default: []
    t.text "expected_results"
    t.jsonb "notes", default: {}
    t.string "category", default: "functional"
    t.string "status", default: "draft"
    t.text "preconditions"
    t.integer "estimated_duration"
    t.text "tags"
    t.uuid "user_id", null: false
    t.uuid "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_test_cases_on_category"
    t.index ["organization_id", "status"], name: "index_test_cases_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_test_cases_on_organization_id"
    t.index ["priority"], name: "index_test_cases_on_priority"
    t.index ["status"], name: "index_test_cases_on_status"
    t.index ["user_id"], name: "index_test_cases_on_user_id"
  end

  create_table "test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "test_run_id", null: false
    t.string "name", null: false
    t.string "classname"
    t.string "status", default: "passed", null: false
    t.decimal "time", precision: 10, scale: 3
    t.text "failure_message"
    t.string "failure_type"
    t.text "failure_stacktrace"
    t.text "system_out"
    t.text "system_err"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classname"], name: "index_test_results_on_classname"
    t.index ["status"], name: "index_test_results_on_status"
    t.index ["test_run_id", "classname"], name: "index_test_results_on_test_run_id_and_classname"
    t.index ["test_run_id", "status"], name: "index_test_results_on_test_run_id_and_status"
    t.index ["test_run_id"], name: "index_test_results_on_test_run_id"
  end

  create_table "test_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "environment"
    t.string "test_suite"
    t.text "xml_file"
    t.string "status", default: "pending", null: false
    t.jsonb "results_summary", default: {}
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_test_runs_on_created_at"
    t.index ["environment"], name: "index_test_runs_on_environment"
    t.index ["organization_id", "created_at"], name: "index_test_runs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_test_runs_on_organization_id"
    t.index ["status"], name: "index_test_runs_on_status"
    t.index ["user_id"], name: "index_test_runs_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "first_name"
    t.string "last_name"
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "organization_users", "organizations"
  add_foreign_key "organization_users", "users"
  add_foreign_key "test_cases", "organizations"
  add_foreign_key "test_cases", "users"
  add_foreign_key "test_results", "test_runs"
  add_foreign_key "test_runs", "organizations"
  add_foreign_key "test_runs", "users"
end
