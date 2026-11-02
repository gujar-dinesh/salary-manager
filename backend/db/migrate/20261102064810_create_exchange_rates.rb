class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, null: false
      t.decimal :usd_rate, precision: 12, scale: 6, null: false
      t.timestamps
    end

    add_index :exchange_rates, :currency, unique: true
  end
end
