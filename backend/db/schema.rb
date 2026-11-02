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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_082041) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "countries", force: :cascade do |t|
    t.string "code", limit: 2, null: false
    t.string "name", limit: 100, null: false
    t.string "currency", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["name"], name: "index_countries_on_name", unique: true
    t.check_constraint "code::text ~ '^[A-Z]{2}$'::text", name: "countries_code_format"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_departments_on_lower_name", unique: true
    t.check_constraint "btrim(name::text) <> ''::text", name: "departments_name_present"
  end

  create_table "employees", force: :cascade do |t|
    t.string "full_name", limit: 100, null: false
    t.string "email", limit: 254, null: false
    t.decimal "salary", precision: 12, scale: 2, null: false
    t.string "employment_type", default: "full_time", null: false
    t.date "hire_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "country_id", null: false
    t.bigint "department_id", null: false
    t.bigint "job_title_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.index "lower((email)::text)", name: "index_employees_on_lower_email", unique: true
    t.index ["country_id", "job_title_id"], name: "index_employees_on_country_id_and_job_title_id"
    t.index ["country_id", "salary"], name: "index_employees_on_country_id_and_salary"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["full_name"], name: "index_employees_on_full_name"
    t.index ["full_name"], name: "index_employees_on_full_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["hire_date"], name: "index_employees_on_hire_date"
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
    t.index ["salary"], name: "index_employees_on_salary"
    t.check_constraint "btrim(full_name::text) <> ''::text", name: "employees_full_name_present"
    t.check_constraint "email::text ~ '^[^@[:space:]]+@[^@[:space:]]+$'::text", name: "employees_email_format"
    t.check_constraint "employment_type::text = ANY (ARRAY['full_time'::character varying::text, 'part_time'::character varying::text, 'contractor'::character varying::text])", name: "employees_employment_type_valid"
    t.check_constraint "salary > 0::numeric", name: "employees_salary_positive"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency", limit: 3, null: false
    t.decimal "usd_rate", precision: 12, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_exchange_rates_on_currency", unique: true
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "exchange_rates_currency_format"
    t.check_constraint "usd_rate > 0::numeric", name: "exchange_rates_usd_rate_positive"
  end

  create_table "job_titles", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_job_titles_on_lower_name", unique: true
    t.check_constraint "btrim(name::text) <> ''::text", name: "job_titles_name_present"
  end

  create_table "salary_changes", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.decimal "old_salary", precision: 12, scale: 2, null: false
    t.decimal "new_salary", precision: 12, scale: 2, null: false
    t.string "currency", limit: 3, null: false
    t.datetime "created_at", null: false
    t.index ["employee_id", "created_at", "id"], name: "index_salary_changes_on_employee_history", order: { created_at: :desc, id: :desc }
    t.check_constraint "old_salary > 0::numeric AND new_salary > 0::numeric", name: "salary_changes_salaries_positive"
  end

  add_foreign_key "countries", "exchange_rates", column: "currency", primary_key: "currency"
  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "salary_changes", "employees", on_delete: :cascade
  add_foreign_key "salary_changes", "exchange_rates", column: "currency", primary_key: "currency"
end
