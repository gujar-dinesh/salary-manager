class ReplaceSalaryChangesEmployeeIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :salary_changes, :employee_id
    add_index :salary_changes, [ :employee_id, :created_at, :id ], order: { created_at: :desc, id: :desc },
                              name: "index_salary_changes_on_employee_history"
  end
end
