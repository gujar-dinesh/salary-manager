class AddLockVersionToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :lock_version, :integer, null: false, default: 0
  end
end
