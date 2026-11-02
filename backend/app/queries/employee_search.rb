class EmployeeSearch
  SORTABLE = %w[full_name salary hire_date].freeze
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  MAX_QUERY_LENGTH = 100

  attr_reader :page, :per_page

  def initialize(params)
    @params = params
    @page = [ params[:page].to_i, 1 ].max
    @per_page = params[:per_page].present? ? params[:per_page].to_i.clamp(1, MAX_PER_PAGE) : DEFAULT_PER_PAGE
  end

  def results
    sorted(filtered).limit(per_page).offset((page - 1) * per_page)
  end

  def total
    @total ||= filtered.count
  end

  def total_pages
    (total.to_f / per_page).ceil
  end

  private

  attr_reader :params

  def filtered
    scope = Employee.all
    scope = scope.where(country: params[:country]) if params[:country].present?
    scope = scope.where(department: params[:department]) if params[:department].present?
    scope = scope.where(job_title: params[:job_title]) if params[:job_title].present?

    if params[:q].present?
      term = "%#{Employee.sanitize_sql_like(params[:q].strip.first(MAX_QUERY_LENGTH))}%"
      scope = scope.where("full_name LIKE :term OR email LIKE :term", term: term)
    end

    scope
  end

  def sorted(scope)
    column = SORTABLE.include?(params[:sort]) ? params[:sort] : "full_name"
    direction = params[:direction] == "desc" ? :desc : :asc

    # Salaries in different currencies are only comparable once converted to USD.
    if column == "salary" && params[:country].blank?
      return scope.select("employees.*")
                  .joins("LEFT JOIN exchange_rates ON exchange_rates.currency = employees.currency")
                  .order(Arel.sql("employees.salary * COALESCE(exchange_rates.usd_rate, 0) #{direction}"), id: direction)
    end

    scope.order(column => direction, id: direction)
  end
end
