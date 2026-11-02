class SplitSalaryChangeCurrency < ActiveRecord::Migration[8.1]
  def change
    rename_column :salary_changes, :currency, :new_currency
    add_column :salary_changes, :old_currency, :string, limit: 3

    reversible do |dir|
      dir.up { execute "UPDATE salary_changes SET old_currency = new_currency" }
    end

    change_column_null :salary_changes, :old_currency, false
    add_foreign_key :salary_changes, :exchange_rates, column: :old_currency, primary_key: :currency
  end
end
