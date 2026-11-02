class CreateSalaryChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :salary_changes do |t|
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :old_salary, precision: 12, scale: 2, null: false
      t.decimal :new_salary, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.datetime :created_at, null: false
    end
  end
end
