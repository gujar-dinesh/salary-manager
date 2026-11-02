class EmployeeSerializer
  FIELDS = %i[id full_name email job_title department country currency employment_type hire_date].freeze

  def initialize(employee, with_history: false)
    @employee = employee
    @with_history = with_history
  end

  def as_json(*)
    json = @employee.slice(*FIELDS).merge("salary" => @employee.salary.to_f)
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
