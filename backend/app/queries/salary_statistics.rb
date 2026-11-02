class SalaryStatistics
  def self.by_country
    new(Employee.all, :country).rows.map { |row| row.merge(currency: Country.currency_for(row[:group])) }
  end

  def self.by_job_title(country)
    currency = Country.currency_for(country)
    new(Employee.where(country: country), :job_title).rows.map { |row| row.merge(currency: currency) }
  end

  GROUPABLE = %i[country job_title department].freeze

  def initialize(scope, column)
    raise ArgumentError, "can't group by #{column}" unless GROUPABLE.include?(column)

    @scope = scope
    @column = column
  end

  def rows
    @scope.group(@column).order(@column).pluck(
      @column,
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
