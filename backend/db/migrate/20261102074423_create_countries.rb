class CreateCountries < ActiveRecord::Migration[8.1]
  COUNTRIES = {
    "AU" => [ "Australia", "AUD" ], "BR" => [ "Brazil", "BRL" ], "CA" => [ "Canada", "CAD" ],
    "FR" => [ "France", "EUR" ], "DE" => [ "Germany", "EUR" ], "IN" => [ "India", "INR" ],
    "JP" => [ "Japan", "JPY" ], "SG" => [ "Singapore", "SGD" ], "GB" => [ "United Kingdom", "GBP" ],
    "US" => [ "United States", "USD" ]
  }.freeze

  def up
    create_table :countries do |t|
      t.string :code, null: false, limit: 2
      t.string :name, null: false
      t.string :currency, null: false
      t.timestamps
    end
    add_index :countries, :code, unique: true
    add_index :countries, :name, unique: true
    add_foreign_key :countries, :exchange_rates, column: :currency, primary_key: :currency

    values = COUNTRIES.map { |code, (name, currency)| "(#{quote(code)}, #{quote(name)}, #{quote(currency)})" }.join(", ")
    execute <<~SQL
      INSERT INTO countries (code, name, currency, created_at, updated_at)
      SELECT code, name, currency, NOW(), NOW() FROM (VALUES #{values}) AS data(code, name, currency)
      WHERE name IN (SELECT DISTINCT country FROM employees)
    SQL

    add_reference :employees, :country, foreign_key: true, index: false
    execute "UPDATE employees SET country_id = countries.id FROM countries WHERE countries.name = employees.country"
    change_column_null :employees, :country_id, false

    remove_index :employees, [ :country, :salary ]
    remove_index :employees, [ :country, :job_title ]
    remove_column :employees, :country
    remove_column :employees, :currency
    add_index :employees, [ :country_id, :salary ]
    add_index :employees, [ :country_id, :job_title ]
  end

  def down
    remove_index :employees, [ :country_id, :job_title ]
    remove_index :employees, [ :country_id, :salary ]

    add_column :employees, :country, :string
    add_column :employees, :currency, :string
    execute <<~SQL
      UPDATE employees SET country = countries.name, currency = countries.currency
      FROM countries WHERE countries.id = employees.country_id
    SQL
    change_column_null :employees, :country, false
    change_column_null :employees, :currency, false
    remove_reference :employees, :country, foreign_key: true, index: false
    drop_table :countries

    add_index :employees, [ :country, :salary ]
    add_index :employees, [ :country, :job_title ]
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
