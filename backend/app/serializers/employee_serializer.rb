class EmployeeSerializer
  def initialize(employee, with_history: false)
    @employee = employee
    @with_history = with_history
  end

  def as_json(*)
    json = {
      "id" => @employee.id,
      "full_name" => @employee.full_name,
      "email" => @employee.email,
      "job_title" => @employee.job_title.name,
      "department" => @employee.department.name,
      "country" => @employee.country.name,
      "currency" => @employee.currency,
      "salary" => @employee.salary.to_f,
      "employment_type" => @employee.employment_type,
      "hire_date" => @employee.hire_date
    }
    json["salary_changes"] = salary_changes if @with_history
    json
  end

  private

  def salary_changes
    @employee.salary_changes.map do |change|
      {
        old_salary: change.old_salary.to_f,
        new_salary: change.new_salary.to_f,
        currency: change.currency,
        created_at: change.created_at
      }
    end
  end
end
