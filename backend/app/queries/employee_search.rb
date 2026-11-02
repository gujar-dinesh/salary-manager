class EmployeeSearch
  SORTABLE = %w[full_name salary hire_date].freeze
  MAX_QUERY_LENGTH = 100

  def initialize(params)
    @params = params
  end

  def scope
    sorted(filtered)
  end

  def count
    filtered.count
  end

  private

  attr_reader :params

  def filtered
    scope = Employee.all
    scope = scope.where(country_id: Country.with_name(params[:country]).select(:id)) if params[:country].present?
    scope = scope.where(department_id: Department.with_name(params[:department]).select(:id)) if params[:department].present?
    scope = scope.where(job_title_id: JobTitle.with_name(params[:job_title]).select(:id)) if params[:job_title].present?

    if params[:q].present?
      term = "%#{Employee.sanitize_sql_like(params[:q].strip.first(MAX_QUERY_LENGTH))}%"
      scope = scope.where("full_name ILIKE :term OR email ILIKE :term", term: term)
    end

    scope
  end

  def sorted(scope)
    column = SORTABLE.include?(params[:sort]) ? params[:sort] : "full_name"
    direction = params[:direction] == "desc" ? "DESC" : "ASC"

    # Salaries in different currencies are only comparable once converted to USD.
    if column == "salary" && params[:country].blank?
      scope.with_usd_salary.order(Arel.sql("#{Employee::USD_SALARY} #{direction}, employees.id #{direction}"))
    else
      scope.order(column => direction.downcase, id: direction.downcase)
    end
  end
end
