class AddRemainingIntegrityConstraints < ActiveRecord::Migration[8.1]
  def up
    change_column :employees, :full_name, :string, limit: 100, null: false
    change_column :employees, :email, :string, limit: 254, null: false
    remove_index :employees, :email, name: "index_employees_on_email"
    add_index :employees, "LOWER(email)", unique: true, name: "index_employees_on_lower_email"
    add_check_constraint :employees, "btrim(full_name) <> ''", name: "employees_full_name_present"
    add_check_constraint :employees, "email ~ '^[^@[:space:]]+@[^@[:space:]]+$'", name: "employees_email_format"

    %i[departments job_titles].each do |table|
      change_column table, :name, :string, limit: 100, null: false
      add_check_constraint table, "btrim(name) <> ''", name: "#{table}_name_present"
    end

    change_column :countries, :name, :string, limit: 100, null: false
    change_column :countries, :currency, :string, limit: 3, null: false
    add_check_constraint :countries, "code ~ '^[A-Z]{2}$'", name: "countries_code_format"

    change_column :exchange_rates, :currency, :string, limit: 3, null: false
    add_check_constraint :exchange_rates, "currency ~ '^[A-Z]{3}$'", name: "exchange_rates_currency_format"
    add_check_constraint :exchange_rates, "usd_rate > 0", name: "exchange_rates_usd_rate_positive"

    change_column :salary_changes, :currency, :string, limit: 3, null: false
    add_foreign_key :salary_changes, :exchange_rates, column: :currency, primary_key: :currency
  end

  def down
    remove_foreign_key :salary_changes, column: :currency
    change_column :salary_changes, :currency, :string, null: false

    remove_check_constraint :exchange_rates, name: "exchange_rates_usd_rate_positive"
    remove_check_constraint :exchange_rates, name: "exchange_rates_currency_format"
    change_column :exchange_rates, :currency, :string, null: false

    remove_check_constraint :countries, name: "countries_code_format"
    change_column :countries, :currency, :string, null: false
    change_column :countries, :name, :string, null: false

    %i[departments job_titles].each do |table|
      remove_check_constraint table, name: "#{table}_name_present"
      change_column table, :name, :string, null: false
    end

    remove_check_constraint :employees, name: "employees_email_format"
    remove_check_constraint :employees, name: "employees_full_name_present"
    remove_index :employees, name: "index_employees_on_lower_email"
    add_index :employees, :email, unique: true
    change_column :employees, :email, :string, null: false
    change_column :employees, :full_name, :string, null: false
  end
end
