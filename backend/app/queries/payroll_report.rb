class PayrollReport
  GROUPABLE = %i[country department].freeze

  def self.overview
    report = new
    by_country = report.totals_by(:country)

    {
      headcount: by_country.sum { |row| row[:headcount] },
      payroll_usd: by_country.sum { |row| row[:payroll_usd] }.round(2),
      by_country: by_country,
      by_department: report.totals_by(:department)
    }
  end

  def totals_by(column)
    raise ArgumentError, "can't group by #{column}" unless GROUPABLE.include?(column)

    Employee.with_usd_salary
            .group(column)
            .order(column)
            .pluck(column, Arel.sql("COUNT(*)"), Arel.sql("SUM(#{Employee::USD_SALARY})"),
                   Arel.sql("AVG(#{Employee::USD_SALARY})"))
            .map do |group, headcount, payroll, average|
              { group: group, headcount: headcount, payroll_usd: payroll.to_f.round(2), average_usd: average.to_f.round(2) }
            end
  end
end
