class CreateDepartmentsAndJobTitles < ActiveRecord::Migration[8.1]
  LOOKUPS = { departments: :department, job_titles: :job_title }.freeze

  def up
    LOOKUPS.each do |table, column|
      create_table table do |t|
        t.string :name, null: false
        t.timestamps
      end
      add_index table, "LOWER(name)", unique: true, name: "index_#{table}_on_lower_name"

      execute <<~SQL
        INSERT INTO #{table} (name, created_at, updated_at)
        SELECT MIN(#{column}), NOW(), NOW() FROM employees GROUP BY LOWER(#{column})
      SQL

      add_reference :employees, column, foreign_key: true, index: false
      execute <<~SQL
        UPDATE employees SET #{column}_id = #{table}.id
        FROM #{table} WHERE LOWER(#{table}.name) = LOWER(employees.#{column})
      SQL
      change_column_null :employees, :"#{column}_id", false
    end

    remove_index :employees, [ :country_id, :job_title ]
    remove_index :employees, :job_title
    remove_index :employees, :department
    remove_column :employees, :job_title
    remove_column :employees, :department

    add_index :employees, [ :country_id, :job_title_id ]
    add_index :employees, :job_title_id
    add_index :employees, :department_id
  end

  def down
    remove_index :employees, :department_id
    remove_index :employees, :job_title_id
    remove_index :employees, [ :country_id, :job_title_id ]

    LOOKUPS.each do |table, column|
      add_column :employees, column, :string
      execute "UPDATE employees SET #{column} = #{table}.name FROM #{table} WHERE #{table}.id = employees.#{column}_id"
      change_column_null :employees, column, false
      remove_reference :employees, column, foreign_key: true, index: false
      drop_table table
    end

    add_index :employees, :department
    add_index :employees, :job_title
    add_index :employees, [ :country_id, :job_title ]
  end
end
