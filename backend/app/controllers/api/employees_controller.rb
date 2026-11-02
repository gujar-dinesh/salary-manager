module Api
  class EmployeesController < ApplicationController
    rate_limit to: 60, within: 1.minute, only: %i[create update destroy]

    before_action :set_employee, only: %i[show update destroy]

    def index
      search = EmployeeSearch.new(params)

      render json: {
        employees: search.results.map { |employee| EmployeeSerializer.new(employee) },
        meta: { page: search.page, per_page: search.per_page, total: search.total, total_pages: search.total_pages }
      }
    end

    def show
      render json: EmployeeSerializer.new(@employee, with_history: true)
    end

    def create
      employee = Employee.new(employee_params)

      if employee.save
        render json: EmployeeSerializer.new(employee, with_history: true), status: :created
      else
        render_errors(employee)
      end
    end

    def update
      if @employee.update(employee_params)
        render json: EmployeeSerializer.new(@employee, with_history: true)
      else
        render_errors(@employee)
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

    def render_errors(employee)
      render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
    end
  end
end
