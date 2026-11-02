class SalaryStatistics
  # Group name => [association to join, column holding the label]
  GROUPS = {
    country: [ :country, "countries.name" ],
    job_title: [ :job_title, "job_titles.name" ],
    department: [ :department, "departments.name" ]
  }.freeze

  def self.by_country
    currencies = Country.pluck(:name, :currency).to_h
    new(Employee.all, :country).rows.map { |row| row.merge(currency: currencies[row[:group]]) }
  end

  def self.by_job_title(country)
    new(Employee.where(country: country), :job_title).rows.map { |row| row.merge(currency: country.currency) }
  end

  def initialize(scope, group)
    raise ArgumentError, "can't group by #{group}" unless GROUPS.key?(group)

    association, @label = GROUPS[group]
    @scope = scope.joins(association)
  end

  def rows
    @scope.group(Arel.sql(@label)).order(Arel.sql(@label)).pluck(
      Arel.sql(@label),
      Arel.sql("COUNT(*)"),
      Arel.sql("MIN(salary)"),
      Arel.sql("MAX(salary)"),
      Arel.sql("AVG(salary)"),
      Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)")
    ).map do |group, headcount, min, max, average, median|
      {
        group: group,
        headcount: headcount,
        min: min.to_f.round(2),
        max: max.to_f.round(2),
        average: average.to_f.round(2),
        median: median.to_f.round(2)
      }
    end
  end
end
