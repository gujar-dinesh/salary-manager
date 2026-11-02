class AddCheckConstraintsToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :employees, "salary > 0", name: "employees_salary_positive"
    add_check_constraint :employees, "employment_type IN ('full_time', 'part_time', 'contractor')",
                         name: "employees_employment_type_valid"
    add_check_constraint :salary_changes, "old_salary > 0 AND new_salary > 0", name: "salary_changes_salaries_positive"
  end
end
