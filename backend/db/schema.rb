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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_070618) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "employees", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "job_title", null: false
    t.string "department", null: false
    t.string "country", null: false
    t.string "currency", null: false
    t.decimal "salary", precision: 12, scale: 2, null: false
    t.string "employment_type", default: "full_time", null: false
    t.date "hire_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country", "job_title"], name: "index_employees_on_country_and_job_title"
    t.index ["country", "salary"], name: "index_employees_on_country_and_salary"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["email"], name: "index_employees_on_email_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["full_name"], name: "index_employees_on_full_name"
    t.index ["full_name"], name: "index_employees_on_full_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["hire_date"], name: "index_employees_on_hire_date"
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["salary"], name: "index_employees_on_salary"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency", null: false
    t.decimal "usd_rate", precision: 12, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_exchange_rates_on_currency", unique: true
  end

  create_table "salary_changes", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.decimal "old_salary", precision: 12, scale: 2, null: false
    t.decimal "new_salary", precision: 12, scale: 2, null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.index ["employee_id"], name: "index_salary_changes_on_employee_id"
  end

  add_foreign_key "salary_changes", "employees", on_delete: :cascade
end
