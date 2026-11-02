module Api
  class EmployeesController < ApplicationController
    rate_limit to: 60, within: 1.minute, only: %i[create update destroy]

    before_action :set_employee, only: %i[show update destroy]

    def index
      search = EmployeeSearch.new(params)
      pagination = Pagination.new(page: params[:page], per_page: params[:per_page])

      render json: {
        employees: pagination.apply(search.scope).preload(:country, :department, :job_title).map { |employee| EmployeeSerializer.new(employee) },
        meta: pagination.meta(search.count)
      }
    end

    def show
      render json: EmployeeSerializer.new(@employee, with_history: true)
    end

    def create
      employee = Employee.new(employee_attributes)

      if employee.save
        render json: EmployeeSerializer.new(employee, with_history: true), status: :created
      else
        render_errors(employee)
      end
    end

    def update
      if @employee.update(employee_attributes)
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
        countries: Country.order(:name).pluck(:name),
        departments: Department.order(:name).pluck(:name),
        job_titles: JobTitle.order(:name).pluck(:name),
        employment_types: Employee.employment_types.keys
      }
    end

    private

    def set_employee
      @employee = Employee.includes(:country, :department, :job_title).find(params[:id])
    end

    def employee_attributes
      EmployeeAttributes.new(
        params.expect(employee: %i[full_name email job_title department country salary employment_type hire_date lock_version])
      ).to_h
    end

    def render_errors(employee)
      render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
    end
  end
end
