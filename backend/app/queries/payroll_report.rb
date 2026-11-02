class PayrollReport
  # Group name => [extra association to join, column holding the label]. Country is already joined for the rate.
  GROUPS = { country: [ nil, "countries.name" ], department: [ :department, "departments.name" ] }.freeze

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
    raise ArgumentError, "can't group by #{column}" unless GROUPS.key?(column)

    association, label = GROUPS[column]
    label = Arel.sql(label)
    scope = Employee.with_usd_salary
    scope = scope.joins(association) if association

    scope
            .group(label)
            .order(label)
            .pluck(label, Arel.sql("COUNT(*)"), Arel.sql("SUM(#{Employee::USD_SALARY})"),
                   Arel.sql("AVG(#{Employee::USD_SALARY})"))
            .map do |group, headcount, payroll, average|
              { group: group, headcount: headcount, payroll_usd: payroll.to_f.round(2), average_usd: average.to_f.round(2) }
            end
  end
end
