class EmployeeSeeder
  # Share of headcount and pay level relative to the US, by ISO country code (see ReferenceData).
  COUNTRIES = {
    "IN" => [ 30, 0.25 ],
    "US" => [ 25, 1.0 ],
    "GB" => [ 10, 0.8 ],
    "DE" => [ 8, 0.8 ],
    "CA" => [ 7, 0.8 ],
    "FR" => [ 5, 0.7 ],
    "AU" => [ 5, 0.85 ],
    "SG" => [ 4, 0.75 ],
    "JP" => [ 3, 0.6 ],
    "BR" => [ 3, 0.35 ]
  }.freeze

  # Base annual salary in USD for a US employee.
  JOBS = {
    "Engineering" => { "Software Engineer" => 120_000, "Senior Software Engineer" => 160_000,
                       "Engineering Manager" => 190_000, "QA Engineer" => 95_000, "DevOps Engineer" => 130_000 },
    "Product" => { "Product Manager" => 150_000, "Product Designer" => 115_000 },
    "Sales" => { "Account Executive" => 90_000, "Sales Manager" => 130_000 },
    "Marketing" => { "Marketing Specialist" => 70_000, "Marketing Manager" => 115_000 },
    "Finance" => { "Financial Analyst" => 85_000, "Accountant" => 75_000 },
    "People" => { "HR Generalist" => 70_000, "Recruiter" => 75_000 },
    "Operations" => { "Operations Analyst" => 72_000, "Customer Support Specialist" => 50_000 }
  }.freeze

  FIRST_NAMES = %w[
    Aarav Aisha Akira Alice Amara Ana Arjun Ben Carlos Chen Chloe Daniel Diya Elena Emma Ethan Fatima
    Felix Gabriel Hana Hiro Isabel Ivan James Julia Kabir Kenji Lena Leo Lucas Maria Maya Mei Mohammed
    Nadia Noah Olivia Omar Priya Rahul Ravi Rohan Sakura Sara Sofia Tom Vikram Wei Yuki Zara
  ].freeze

  LAST_NAMES = %w[
    Ahmed Anderson Bauer Brown Costa Dubois Fischer Garcia Gupta Hoffmann Iyer Johnson Kapoor Kim
    Kumar Lee Lopez Martin Mehta Meyer Moreau Muller Nair Nakamura Nguyen Patel Reddy Rossi Santos
    Sato Schmidt Shah Silva Singh Smith Suzuki Tan Taylor Thomas Wang Watanabe Williams Wilson Wong
  ].freeze

  # Demo data replaces every employee, so production data is only replaced when explicitly forced.
  def self.seed(environment: Rails.env, force: false, count: 10_000)
    return :skipped if environment.to_s == "production" && !force && Employee.exists?

    new(count: count).run
    :seeded
  end

  def initialize(count: 10_000, seed: 42)
    @count = count
    @random = Random.new(seed)
  end

  def run
    now = Time.current

    Employee.transaction do
      SalaryChange.delete_all
      Employee.delete_all
      JobTitle.delete_all
      Department.delete_all
      ReferenceData.load
      create_departments_and_job_titles
      @country_ids = Country.pluck(:code, :id).to_h
      @usd_rates = Country.joins(:exchange_rate).pluck(:code, :usd_rate).to_h.transform_values(&:to_f)

      @count.times.each_slice(1000) do |batch|
        Employee.insert_all!(batch.map { |i| build_row(i, now) })
      end
    end
  end

  private

  def create_departments_and_job_titles
    @department_ids = JOBS.keys.to_h { |name| [ name, Department.create!(name: name).id ] }
    @job_title_ids = JOBS.values.flat_map(&:keys).uniq.to_h { |name| [ name, JobTitle.create!(name: name).id ] }
  end

  def build_row(index, now)
    first = FIRST_NAMES.sample(random: @random)
    last = LAST_NAMES.sample(random: @random)
    country = pick_country
    department = JOBS.keys.sample(random: @random)
    job_title, base_salary = JOBS[department].to_a.sample(random: @random)

    {
      full_name: "#{first} #{last}",
      email: "#{first}.#{last}#{index + 1}@acme.com".downcase,
      job_title_id: @job_title_ids.fetch(job_title),
      department_id: @department_ids.fetch(department),
      country_id: @country_ids.fetch(country),
      salary: local_salary(base_salary, country),
      employment_type: pick_employment_type,
      hire_date: Date.new(2012, 1, 1) + @random.rand(5300),
      created_at: now,
      updated_at: now
    }
  end

  def pick_country
    roll = @random.rand(100)
    COUNTRIES.each do |country, (share, _)|
      return country if roll < share
      roll -= share
    end
  end

  def pick_employment_type
    roll = @random.rand(100)
    return "contractor" if roll < 7
    return "part_time" if roll < 15
    "full_time"
  end

  def local_salary(base_salary, country)
    usd = base_salary * COUNTRIES[country].last * @random.rand(0.8..1.25)
    local = usd / @usd_rates.fetch(country)
    step = local > 1_000_000 ? 10_000 : 1_000
    ((local / step).round * step).to_i
  end
end
