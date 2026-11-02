class AddSortIndexesToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_index :employees, :salary
    add_index :employees, :hire_date
    add_index :employees, [ :country, :salary ]
  end
end
