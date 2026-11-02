module Api
  class EmployeesController < ApplicationController
    before_action :set_employee, only: %i[show update destroy]

    def index
      search = EmployeeSearch.new(params)

      render json: {
        employees: search.results.map { |employee| employee_json(employee) },
        meta: { page: search.page, per_page: search.per_page, total: search.total, total_pages: search.total_pages }
      }
    end

    def show
      render json: employee_json(@employee, with_history: true)
    end

    def create
      employee = Employee.new(employee_params)

      if employee.save
        render json: employee_json(employee, with_history: true), status: :created
      else
        render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
      end
    end

    def update
      if @employee.update(employee_params)
        render json: employee_json(@employee.reload, with_history: true)
      else
        render json: { errors: @employee.errors.to_hash }, status: :unprocessable_content
      end
    end

    def destroy
      @employee.destroy!
      head :no_content
    end

    def options
      render json: {
        countries: Employee::CURRENCY_BY_COUNTRY.keys,
        departments: Employee.distinct.order(:department).pluck(:department),
        job_titles: Employee.distinct.order(:job_title).pluck(:job_title),
        employment_types: Employee::EMPLOYMENT_TYPES
      }
    end

    private

    def set_employee
      @employee = Employee.find(params[:id])
    end

    def employee_params
      params.expect(employee: %i[full_name email job_title department country salary employment_type hire_date])
    end

    def employee_json(employee, with_history: false)
      json = employee.slice(:id, :full_name, :email, :job_title, :department, :country, :currency,
                            :employment_type, :hire_date)
      json[:salary] = employee.salary.to_f

      if with_history
        json[:salary_changes] = employee.salary_changes.map do |change|
          { old_salary: change.old_salary.to_f, new_salary: change.new_salary.to_f, currency: change.currency,
            created_at: change.created_at }
        end
      end

      json
    end
  end
end
