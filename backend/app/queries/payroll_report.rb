class PayrollReport
  GROUPS = { country: "countries.name", department: "employees.department" }.freeze

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

    label = Arel.sql(GROUPS[column])
    Employee.with_usd_salary
            .group(label)
            .order(label)
            .pluck(label, Arel.sql("COUNT(*)"), Arel.sql("SUM(#{Employee::USD_SALARY})"),
                   Arel.sql("AVG(#{Employee::USD_SALARY})"))
            .map do |group, headcount, payroll, average|
              { group: group, headcount: headcount, payroll_usd: payroll.to_f.round(2), average_usd: average.to_f.round(2) }
            end
  end
end
