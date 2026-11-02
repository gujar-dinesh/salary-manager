class EmployeeSeeder
  USD_RATES = {
    "USD" => 1.0, "EUR" => 1.08, "GBP" => 1.27, "INR" => 0.012, "CAD" => 0.73,
    "AUD" => 0.66, "SGD" => 0.74, "JPY" => 0.0067, "BRL" => 0.18
  }.freeze

  # Share of headcount and pay level relative to the US.
  COUNTRIES = {
    "India" => [ 30, 0.25 ],
    "United States" => [ 25, 1.0 ],
    "United Kingdom" => [ 10, 0.8 ],
    "Germany" => [ 8, 0.8 ],
    "Canada" => [ 7, 0.8 ],
    "France" => [ 5, 0.7 ],
    "Australia" => [ 5, 0.85 ],
    "Singapore" => [ 4, 0.75 ],
    "Japan" => [ 3, 0.6 ],
    "Brazil" => [ 3, 0.35 ]
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

  def initialize(count: 10_000, seed: 42)
    @count = count
    @random = Random.new(seed)
  end

  def run
    now = Time.current

    Employee.transaction do
      SalaryChange.delete_all
      Employee.delete_all
      ExchangeRate.delete_all

      ExchangeRate.insert_all!(USD_RATES.map { |currency, rate| { currency: currency, usd_rate: rate, created_at: now, updated_at: now } })
      @count.times.each_slice(1000) do |batch|
        Employee.insert_all!(batch.map { |i| build_row(i, now) })
      end
    end
  end

  private

  def build_row(index, now)
    first = FIRST_NAMES.sample(random: @random)
    last = LAST_NAMES.sample(random: @random)
    country = pick_country
    department = JOBS.keys.sample(random: @random)
    job_title, base_salary = JOBS[department].to_a.sample(random: @random)
    currency = Employee::CURRENCY_BY_COUNTRY[country]

    {
      full_name: "#{first} #{last}",
      email: "#{first}.#{last}#{index + 1}@acme.com".downcase,
      job_title: job_title,
      department: department,
      country: country,
      currency: currency,
      salary: local_salary(base_salary, country, currency),
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

  def local_salary(base_salary, country, currency)
    usd = base_salary * COUNTRIES[country].last * @random.rand(0.8..1.25)
    local = usd / USD_RATES[currency]
    step = local > 1_000_000 ? 10_000 : 1_000
    ((local / step).round * step).to_i
  end
end
