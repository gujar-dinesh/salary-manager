class SalaryInsights
  GROUPABLE = %i[country job_title department].freeze

  def self.by_country
    stats(Employee.all, :country) { |country| Employee::CURRENCY_BY_COUNTRY[country] }
  end

  def self.by_job_title(country)
    currency = Employee::CURRENCY_BY_COUNTRY.fetch(country)
    stats(Employee.where(country: country), :job_title) { currency }
  end

  def self.overview
    by_country = usd_totals(:country)

    {
      headcount: by_country.sum { |row| row[:headcount] },
      payroll_usd: by_country.sum { |row| row[:payroll_usd] }.round(2),
      by_country: by_country,
      by_department: usd_totals(:department)
    }
  end

  # SQLite has no MEDIAN, so salaries are ranked within each group and the middle one or two are averaged.
  # Everything is computed in a single pass over the employees table.
  def self.stats(scope, column)
    check_column!(column)

    ranked = scope.select(
      "#{column} AS grp",
      :salary,
      "ROW_NUMBER() OVER (PARTITION BY #{column} ORDER BY salary) AS position",
      "COUNT(*) OVER (PARTITION BY #{column}) AS group_size"
    )

    rows = Employee.unscoped.from(ranked, :ranked).group(:grp).order(:grp).pluck(
      :grp,
      Arel.sql("COUNT(*)"),
      Arel.sql("MIN(salary)"),
      Arel.sql("MAX(salary)"),
      Arel.sql("AVG(salary)"),
      Arel.sql("AVG(CASE WHEN position IN ((group_size + 1) / 2, (group_size + 2) / 2) THEN salary END)")
    )

    rows.map do |group, headcount, min, max, average, median|
      {
        group: group,
        currency: yield(group),
        headcount: headcount,
        min: min.to_f.round(2),
        max: max.to_f.round(2),
        average: average.to_f.round(2),
        median: median.to_f.round(2)
      }
    end
  end

  def self.usd_totals(column)
    check_column!(column)

    Employee.joins("JOIN exchange_rates ON exchange_rates.currency = employees.currency")
            .group(column)
            .order(column)
            .pluck(column, Arel.sql("COUNT(*)"), Arel.sql("SUM(salary * usd_rate)"))
            .map do |group, headcount, payroll|
              payroll = payroll.to_f.round(2)
              { group: group, headcount: headcount, payroll_usd: payroll, average_usd: (payroll / headcount).round(2) }
            end
  end

  def self.check_column!(column)
    raise ArgumentError, "can't group by #{column}" unless GROUPABLE.include?(column)
  end
  private_class_method :check_column!
end
